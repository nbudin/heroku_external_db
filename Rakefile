require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "heroku_external_db"
  gem.homepage = "http://github.com/nbudin/heroku_external_db"
  gem.license = "MIT"
  gem.summary = %Q{Makes it easy to connect Heroku apps to external databases}
  gem.description = <<-DESC
  heroku_external_db lets you specify multiple databases using Heroku-style DATABASE_URL parameters, wire
  them up to different ActiveRecord configurations, and automatically configure it from the Rails
  environment.  It also adds support for the :sslca configuration parameter so you can talk to external
  MySQL servers over SSL.
  DESC
  gem.email = "natbudin@gmail.com"
  gem.authors = ["Nat Budin"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require "rspec/core/rake_task"
desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
  t.verbose = false
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'spec'
  test.pattern = 'spec/*_spec.rb'
  test.verbose = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "heroku_external_db #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
