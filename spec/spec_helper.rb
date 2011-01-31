require 'rspec'
require 'rails'
require 'active_record'
require File.join(File.dirname(__FILE__), '..', 'lib', 'heroku_external_db')


Rspec.configure do |c|
  c.mock_with :mocha
end

