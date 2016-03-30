ruby "2.3.0"

source "https://rubygems.org"

gem "actionpack", ">= 5.0.0.beta3", "< 5.1"
gem "actionview", ">= 5.0.0.beta3", "< 5.1"
gem "activejob", ">= 5.0.0.beta3", "< 5.1"
gem "activemodel", ">= 5.0.0.beta3", "< 5.1"
gem "activerecord", ">= 5.0.0.beta3", "< 5.1"
gem "activesupport", ">= 5.0.0.beta3", "< 5.1"
gem "addressable"
gem "bundler", ">= 1.3.0", "< 2.0"
gem "coffee-rails", "~> 4.1.0"
gem "compass-rails"
gem "escobar"
gem "fernet"
gem "jbuilder", "~> 2.0"
gem "jquery-rails"
gem "librato-rails"
gem "lograge"
gem "omniauth-github"
gem "omniauth-heroku", "0.2.0"
gem "omniauth-slack", "2.3.0"
gem "pg"
gem "puma"
gem "railties", ">= 5.0.0.beta3", "< 5.1"
gem "rails_stdout_logging", "0.0.4"
gem "redis", "~> 3.0"
gem "rollbar"
gem "sidekiq"
gem "sass-rails", "~> 5.0"
gem "sprockets-rails"
gem "turbolinks"
gem "uglifier", ">= 1.3.0"

group :development, :test do
  gem "brakeman"
  gem "byebug"
  gem "dotenv-rails"
  gem "pry"
  gem "rspec-rails", "3.5.0.beta2"
  gem "rubocop"
end

group :test do
  gem "capybara"
  gem "codeclimate-test-reporter", require: nil
  gem "timecop"
  gem "webmock", require: false
end

group :development do
  gem "foreman"
  gem "spring"
  gem "web-console", "~> 3.0"
end

group :staging, :production do
  gem "rails_12factor"
end
