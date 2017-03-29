source "https://rubygems.org"

ruby "2.4.1"

gem "autoprefixer-rails", "~> 6.7.7"
gem "delayed_job_active_record", "~> 4.1.1"
gem 'devise', '~> 4.2.0'
gem 'devise_cas_authenticatable', '~> 1.9.2'
gem "flutie"
gem "honeybadger", "~> 3.1.0"
gem "jquery-rails", "~> 4.3.1"
gem "jquery-ui-rails", "~> 6.0.1"
gem "normalize-rails", "~> 3.0.0"
gem "pg", "~> 0.20.0"
gem "puma", "~> 3.8.2"
gem "pundit", "~> 1.1.0"
gem "rack-canonical-host"
gem "rails", "~> 5.0.0"
gem "recipient_interceptor"
gem "sass-rails", "~> 5.0"
gem "simple_form", "~> 3.4.0"
gem "skylight", "~> 1.1.0"
gem "sprockets", ">= 3.0.0"
gem "sprockets-es6"
gem "title"
gem "uglifier", "~> 3.1.11"

# for UserGenerator
gem 'ffaker', '~> 2.4.0'

# Front-End Styling
gem 'foundation-rails', '~> 6.3.0.0'

group :development do
  gem "listen"
  gem "spring", "~> 2.0.1"
  gem "spring-commands-rspec"
  gem "web-console", "~> 3.4.0"
  gem "yard", "~> 0.9.8"
end

group :development, :test do
  gem "awesome_print"
  gem "bullet", "~> 5.5.1"
  gem "bundler-audit", ">= 0.5.0", require: false
  gem "dotenv-rails", "~> 2.2.0"
  gem "factory_girl_rails", "~> 4.8.0"
  gem "pry-byebug", "~> 3.4.2"
  gem "pry-rails", "~> 0.3.6"
  gem "rspec-rails", "~> 3.6.0.beta2"
  gem "rubocop", "~> 0.48.0", require: false
  gem "rubocop-rspec", "~> 1.15.0", require: false
  # gem 'ruby-progressbar', '~> 1.8.0'
end

group :development, :staging do
  gem "rack-mini-profiler", "~> 0.10.2", require: false
end

group :test do
  gem "capybara-webkit", "~> 1.14.0"
  gem "database_cleaner"
  gem "formulaic", "~> 0.4.0"
  gem "launchy"
  gem "shoulda-matchers"
  gem "simplecov", "~> 0.14.1", require: false
  gem "codeclimate-test-reporter", "~> 1.0.0"
  gem "timecop"
  gem "webmock"
end

group :staging, :production do
  gem "daemons", "~> 1.2.4"
  gem "rack-timeout"
  gem "rails_stdout_logging"
end

gem 'high_voltage'
