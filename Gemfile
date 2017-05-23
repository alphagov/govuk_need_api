source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.0.2'

gem 'mongoid', '~> 6.0'

gem 'plek', '~> 1.11'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '39.2.0'
end

gem 'mongoid_rails_migrations', '1.1.0'

gem 'kaminari', '0.17.0'
gem 'link_header', '0.0.8'

gem 'elasticsearch', '1.0.14'

gem 'logstasher', '0.4.8'

gem 'mlanett-redis-lock', '0.2.7'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '13.2.0'
end

gem 'airbrake', github: 'alphagov/airbrake', branch: 'silence-dep-warnings-for-rails-5'

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :development, :test do
  gem 'govuk-lint'
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
