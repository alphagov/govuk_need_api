source 'https://rubygems.org'

gem 'rails', '3.2.14'

gem 'mongoid', '2.8.1'
gem 'bson_ext', '1.9.2'

gem 'plek', '1.4.0'
gem 'aws-ses', :require => 'aws/ses'

gem 'kaminari', '0.14.1'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '3.1.0'
end

group :test do
  gem 'database_cleaner', '1.1.1', require: false
  gem 'factory_girl_rails', '4.2.1'
  gem 'mocha', '0.13.3', require: false
  gem 'shoulda-context', '1.1.5'
  gem 'simplecov', '0.7.1'
  gem 'simplecov-rcov'
end

gem 'unicorn'
gem 'exception_notification', '2.6.1'
