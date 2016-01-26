source 'https://rubygems.org'

gem 'rails', '4.2.5.1'

gem 'mongoid', '4.0.2'

gem 'plek', '~> 1.11'
gem 'gds-api-adapters', '26.2.0'

gem 'mongoid_rails_migrations', '1.1.0'

gem 'kaminari', '0.16.3'
gem 'link_header', '0.0.8'

gem 'elasticsearch', '1.0.14'

gem 'logstasher', '0.4.8'

gem 'mlanett-redis-lock', '0.2.7'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '11.2.0'
end

gem 'airbrake', '~> 4.3.4'

group :development, :test do
  gem 'govuk-lint', '~> 0.4'
end

group :test do
  gem 'database_cleaner', '1.5.1', require: false
  gem 'factory_girl_rails', '4.5.0'
  gem 'mocha', '1.1.0', require: false
  gem 'shoulda', '3.5.0'
  gem 'shoulda-matchers', '2.8.0'
  gem 'webmock', '1.22.3'
  gem 'test-unit', '~> 3.0'
end

gem 'unicorn'
gem 'whenever', '0.9.4', require: false
