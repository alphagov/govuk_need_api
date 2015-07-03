source 'https://rubygems.org'

gem 'rails', '3.2.22'

gem 'mongoid', '2.8.1'
gem 'bson_ext', '1.9.2'

gem 'plek', '~> 1.10'
gem 'gds-api-adapters', '20.1.1'

gem "mongoid_rails_migrations", "1.0.1"

gem 'kaminari', '0.14.1'
gem 'link_header', '0.0.8'

gem 'elasticsearch', '0.4.1'

gem 'logstasher', '0.4.8'

gem 'mlanett-redis-lock', '0.2.6'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '9.3.0'
end

gem 'airbrake', '~> 4.1.0'

group :test do
  gem 'database_cleaner', '1.1.1', require: false
  gem 'factory_girl_rails', '4.2.1'
  gem 'mocha', '0.14.0', require: false
  gem 'shoulda', '3.5.0'
  gem 'shoulda-matchers', '2.7.0'
  gem 'simplecov', '0.7.1'
  gem 'simplecov-rcov'
  gem 'timecop', '0.6.3'
  gem 'webmock', '1.14.0'
end

gem 'unicorn'
gem 'whenever', '0.8.4', :require => false
