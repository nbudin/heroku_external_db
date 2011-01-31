# Represents an ActiveRecord database configuration to be used in a Heroku app.
# This configuration consists of at least one environment variable, and possibly
# several:
#
# * +[PREFIX]_DATABASE_URL+ - the Heroku-style DATABASE_URL to connect to.  Required.
# * +[PREFIX]_DATABASE_CA+ - the filename of a SSL certificate file which will be 
#   configured as the :sslca for the database.  Useful for encrypted MySQL, e.g.
class HerokuExternalDb
  
  # Each HerokuExternalDb must have a unique prefix for its environment variables.
  # For example, if the prefix was set to +CRAZY+, then the database URL would be
  # taken from +CRAZY_DATABASE_URL+, and the CA filename would be taken from
  # +CRAZY_DATABASE_CA+, if it existed.
  #
  # In typical usage, the prefix will be +EXTERNAL+ by default.
  attr_reader :env_prefix
  
  # The ActiveRecord configuration that will be set up.  Typically this should be
  # the same as your +RAILS_ENV+ environment variable, but some apps may have
  # multiple database connections with different names.
  attr_reader :configuration_name
  attr_writer :ca_path
  
  def initialize(env_prefix, configuration_name)
    @env_prefix = env_prefix
    @configuration_name = configuration_name
  end
  
  # The path in which your SSL CA certificates are stored.  By default, this is
  # +[Rails app root]/config/ca+.
  def ca_path
    @ca_path ||= ca_path_from_rails_root
  end
  
  # Construct a new HerokuExternalDb instance based on the given env_prefix and
  # configuration_name, then install the configuration in ActiveRecord.  Returns
  # the new instance.
  def self.setup_configuration!(env_prefix, configuration_name)
    HerokuExternalDb.new(env_prefix, configuration_name).setup!
  end

  # Construct a HerokuExternalDb instance for the current Rails environment, then
  # install the configuration in ActiveRecord.  You can optionally override the
  # environment variable prefix, which is +EXTERNAL+ by default.  Returns the new 
  # instance.
  #
  # Note that doing this causes DATABASE_URL to be effectively ignored.
  def self.setup_rails_env!(env_prefix='EXTERNAL')
    raise "ENV['RAILS_ENV'] is not set" unless ENV['RAILS_ENV']
    setup_configuration!(env_prefix, ENV['RAILS_ENV'])
  end
  
  # Parse a Heroku-style database URI and return an ActiveRecord configuration hash
  # based on it.  Format is as follows:
  #
  #   <adapter>://[<username>[:<password>]]@<host>[:<port>]/<database>
  def parse_db_uri(db_uri)
    uri = URI.parse(db_uri)
    
    db_config = {
      :adapter => uri.scheme,
      :database => uri.path[1..-1],
      :host => uri.host
    }
    
    if uri.user
      db_config[:username] = uri.user
      db_config[:password] = uri.password if uri.password
    end
    db_config[:port] = uri.port if uri.port
    
    db_config
  end
  
  # Returns a partial ActiveRecord configuration hash for the given SSL CA certificate.
  # Checks to make sure the given filename actually exists, and raises an error if it
  # does not.
  def db_ca_configuration(ca_filename)
    return {} unless ca_filename
    
    raise "ca_path for #{ca_filename} cannot be determined from Rails root; please set it explicitly" unless ca_path
      
    ca_filepath = File.join(ca_path, ca_filename)
    raise "CA file #{ca_filepath} does not exist!" unless File.exists?(ca_filepath)
    
    return { :sslca => ca_filepath }
  end
  
  # Returns an ActiveRecord configuration hash based on the environment variables.
  def db_config
    @db_config ||= begin 
      raise "ENV['#{env_prefix}_DATABASE_URL'] expected but not found!" unless ENV["#{env_prefix}_DATABASE_URL"]
      config = parse_db_uri(ENV["#{env_prefix}_DATABASE_URL"])
    
      if ENV["#{env_prefix}_DATABASE_CA"]
        config.merge!(db_ca_configuration(ENV["#{env_prefix}_DATABASE_CA"]))
      end
      
      config
    end
  end
  
  # Installs an ActiveRecord configuration based on the environment variables, and
  # makes an initial connection to the database.  (This flushes out the connection
  # pool if a different connection has already been established, and tests to
  # make sure we can actually connect.)
  def setup!
    ActiveRecord::Base.configurations[configuration_name] = db_config
    ActiveRecord::Base.establish_connection(configuration_name).connection
    self
  end
  
  protected
  def ca_path_from_rails_root
    if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
      File.join(Rails.root, 'config', 'ca')
    end
  end
end