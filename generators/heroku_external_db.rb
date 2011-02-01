if defined?(Rails::Generators::Base)
  module HerokuExternalDb
    class Generator < Rails::Generators::Base
        def create_initializer_file
          copy_file "initializer.rb", "config/initializers/heroku_external_db.rb"
        end
      end
    end
  end
else
  class HerokuExternalDbGenerator < Rails::Generator::Base
    def manifest
      record do |m|
        m.directory('config/initializers')
        m.file('initializer.rb', "config/initializers/heroku_external_db.rb")
      end
    end
  end
end