# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version       = "1.0.2"

  gem.authors       = ["Nat Budin"]
  gem.email         = ["natbudin@gmail.com"]
  gem.description   = %q{  heroku_external_db lets you specify multiple databases using Heroku-style DATABASE_URL parameters, wire
  them up to different ActiveRecord configurations, and automatically configure it from the Rails
  environment.  It also adds support for the :sslca configuration parameter so you can talk to external
  MySQL servers over SSL.
}
  gem.summary       = %q{Makes it easy to connect Heroku apps to external databases}
  gem.homepage      = %q{http://github.com/nbudin/heroku_external_db}

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "heroku_external_db"
  gem.require_paths = ["lib"]
  gem.licenses      = ["MIT"]

  gem.add_development_dependency "shoulda", ">= 0"
  gem.add_development_dependency "rspec", ">= 2.4.0"
  gem.add_development_dependency "rcov"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "rails", ">= 3.0.0"
end
