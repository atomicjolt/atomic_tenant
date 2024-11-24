source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in atomic_tenant.gemspec.
gemspec

gem 'sqlite3'

gem 'sprockets-rails'

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

group :development, :test, :linter do
  gem "byebug"
  gem "factory_bot_rails"
  gem "ims-lti"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "webmock"
end

group :test do
  gem "launchy"
  gem "rspec"
  gem "rspec-rails", "~>7.0"

  gem "jwt", "~>2.7.0"
  gem "json-jwt"
  gem "httparty"
  gem "database_cleaner"
  gem "atomic_lti"
end

group :ci do
  gem "brakeman"
  gem "pronto"
  gem "pronto-rubocop", require: false
end
