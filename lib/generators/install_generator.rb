module HerokuExternalDb
  module Generators
  end
end

if defined?(Rails::Generators::Base)
  class HerokuExternalDb::Generators::InstallGenerator < Rails::Generators::Base
        def create_initializer_file
          copy_file "initializer.rb", "config/initializers/heroku_external_db.rb"
        end
      end
    end
  end
else
  class HerokuExternalDb::Generators::InstallGenerator < Rails::Generator::Base
    def manifest
      record do |m|
        m.directory('config/initializers')
        m.file('initializer.rb', "config/initializers/heroku_external_db.rb")
      end
    end
  end
end