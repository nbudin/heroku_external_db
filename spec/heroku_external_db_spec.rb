require 'spec_helper'
require 'tempfile'

COMPLETE_DB_URL = "magicdb://joe:secure@db.example.com:12345/super_special_database"
COMPLETE_DB_CONFIG = {
  :adapter => "magicdb",
  :username => "joe",
  :password => "secure",
  :host => "db.example.com",
  :port => 12345,
  :database => "super_special_database"
}

def setup_ca_cert(extdb)
  @cert_path = Tempfile.new("mykey.pem").path
  extdb.ca_path, @cert_filename = File.split(@cert_path)
  
  return @cert_path, @cert_filename
end

describe HerokuExternalDb::Configuration do
  before do
    @extdb = HerokuExternalDb::Configuration.new("GREEN", "red")
  end

  it "initializes based on env_prefix and configuration_name" do
    @extdb.env_prefix.should == "GREEN"
    @extdb.configuration_name.should == "red"
  end
  
  describe "#ca_path" do
    it "should return nil if Rails.root is not available" do
      @extdb.ca_path.should be_nil
    end
    
    it "should figure out CA path based on Rails root" do
      Rails.expects(:root).at_least_once.returns("/my/rails/app")
      @extdb.ca_path.should == "/my/rails/app/config/ca"
    end
    
    it "should allow override" do
      @extdb.ca_path = "/other/rails/app/config/ca"
      @extdb.ca_path.should == "/other/rails/app/config/ca"
    end
  end
  
  describe "#parse_db_uri" do
    context "with minimal URI" do
      before do
        @config = @extdb.parse_db_uri("hyperdb://localhost/loco")
      end
      
      it "should leave unspecified parts as nil" do
        %w{username password port}.each do |key|
          @config.has_key?(key.to_sym).should be_false
        end

        %w{adapter host database}.each do |key|
          @config.has_key?(key.to_sym).should be_true
        end
      end
    end
    
    context "with complete URI" do
      before do
        @config = @extdb.parse_db_uri(COMPLETE_DB_URL)
      end
    
      it "should parse all parts of the URI" do
        COMPLETE_DB_CONFIG.each do |key, value|
          @config[key].should == value
        end
      end
    end
  end
  
  describe "#db_configuration" do
    context "with a CA path" do
      before do
        @cert_path, @cert_filename = setup_ca_cert(@extdb)
      end
      
      it "should return an empty hash if not given a filename" do
        @extdb.db_configuration(nil).should == {}
      end
    
      it "should have the correct pathname to the CA cert" do
        @config = @extdb.db_configuration(:sslca => @cert_filename)
        @config[:sslca].should == @cert_path
      end

      context 'when using X.509' do
        it "should have the correct pathname to the client cert" do
          @config = @extdb.db_configuration(:sslcert => @cert_filename)
          @config[:sslcert].should == @cert_path
        end

        it "should have the correct pathname to the client key" do
          @config = @extdb.db_configuration(:sslkey => @cert_filename)
          @config[:sslkey].should == @cert_path
        end

        it 'should support setting all 3 X.509 certs' do
          @config = @extdb.db_configuration({
            :sslca => @cert_filename,
            :sslcert => @cert_filename,
            :sslkey => @cert_filename,
          })

          # TODO check for distinct values
          @config[:sslca].should == @cert_path
          @config[:sslcert].should == @cert_path
          @config[:sslkey].should == @cert_path
        end
      end
    
      it "should throw an error if the file doesn't exist" do
        File.delete(@cert_path)
        lambda { @extdb.db_configuration(:sslca => @cert_filename) }.should raise_error
      end
    
      after do
        File.delete(@cert_path) if File.exist?(@cert_path)
      end
    end
    
    context "without a CA path" do
      it "should return an empty hash if not given a filename" do
        @extdb.db_configuration(nil).should == {}
      end
      
      it "should raise an error if given a filename" do
        lambda { @extdb.db_configuration(:sslca => "filename") }.should raise_error
      end
    end
  end
  
  describe "#db_config" do
    context "with database URL" do
      before do
        ENV['GREEN_DATABASE_URL'] = COMPLETE_DB_URL
      end
    
      it "should parse the URL path from the environment" do
        @config = @extdb.db_config
      
        COMPLETE_DB_CONFIG.each do |key, value|
          @config[key].should == value
        end
      end
    
      context "with CA" do
        before do
          @cert_path, @cert_filename = setup_ca_cert(@extdb)
          ENV['GREEN_DATABASE_CA'] = @cert_filename
        end
      
        it "should parse the CA path from the environment" do
          @config = @extdb.db_config
          @config[:sslca].should == @cert_path
        end
      
        after do
          File.delete(@cert_path)
          ENV.delete('GREEN_DATABASE_CA')
        end
      end
    
      after do
        ENV.delete('GREEN_DATABASE_URL')
      end
    end
    
    context "without database URL" do
      it "should raise an error" do
        lambda { @extdb.db_config }.should raise_error
      end
    end
  end
  
  context "with mock green/red database objects" do
    before do
      ENV["GREEN_DATABASE_URL"] = COMPLETE_DB_URL
      @mock_pool = mock()
      @mock_pool.expects(:connection).at_least_once
      ActiveRecord::Base.expects(:establish_connection).with("red").at_least_once.returns(@mock_pool)
    end
    
    describe "#setup!" do
      it "should return self" do
        @extdb.setup!.should equal(@extdb)
      end
    end
    
    describe ".setup_configuration!" do
      it "should return a new instance" do
        @new_extdb = HerokuExternalDb.setup_configuration!("GREEN", "red")
        @new_extdb.should be_instance_of(HerokuExternalDb::Configuration)
        @new_extdb.should_not equal(@extdb)
      end
    end
    
    after do
      ENV.delete("GREEN_DATABASE_URL")
    end
  end
      
  describe ".setup_rails_env!" do
    before do
      ENV['EXTERNAL_DATABASE_URL'] = COMPLETE_DB_URL
    end
    
    context "without a RAILS_ENV" do
      it "should raise an error" do
        lambda { HerokuExternalDb.setup_rails_env! }.should raise_error
        lambda { HerokuExternalDb.setup_rails_env!("PURPLE") }.should raise_error
      end
    end
    
    context "with a RAILS_ENV" do
      before do
        ENV['RAILS_ENV'] = "yummy"
        @mock_pool = mock()
        @mock_pool.expects(:connection).at_least_once
        ActiveRecord::Base.expects(:establish_connection).with("yummy").at_least_once.returns(@mock_pool)
      end
      
      it "should return a new instance based on RAILS_ENV" do
        @new_extdb = HerokuExternalDb.setup_rails_env!
        @new_extdb.should be_instance_of(HerokuExternalDb::Configuration)
        @new_extdb.should_not equal(@extdb)
      end
      
      context "with the orange DB URL in env" do
        before do
          ENV['ORANGE_DATABASE_URL'] = "mysql://db.example.org/orange"
        end
        
        it "should allow specifying a different env_prefix" do
          @orange_extdb = HerokuExternalDb.setup_rails_env!("ORANGE")
          ActiveRecord::Base.configurations["yummy"][:database].should == "orange"
        end
        
        after do
          ENV.delete("ORANGE_DATABASE_URL")
        end
      end
      
      after do
        ENV.delete('RAILS_ENV')
      end
    end
      
    after do
      ENV.delete("EXTERNAL_DATABASE_URL")
    end
  end
end
