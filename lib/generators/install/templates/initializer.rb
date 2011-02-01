if ENV['EXTERNAL_DATABASE_URL']
  # If you have additional databases aside from the main app database, add setup_configuration!
  # lines for them here.  For example, if you have a "users" database configured in
  # USERS_DATABASE_URI, add:
  # 
  # HerokuExternalDb.setup_configuration!("USERS", "users")
  #
  # You would then be able to connect to it like so:
  # class User < ActiveRecord::Base
  #   establish_connection :users
  # end
  
  # This has to come last so that it will be the default ActiveRecord configuration.
  HerokuExternalDb.setup_rails_env!
end