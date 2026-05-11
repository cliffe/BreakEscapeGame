source 'https://rubygems.org'

gemspec
gem 'rails', '~> 7.0'

# Pin gem versions for Ruby 2.7.8 compatibility
gem 'nokogiri', '~> 1.15'  # 1.15.7+ required for Ruby 2.7.8
gem 'psych', '~> 3.3'      # Ensure YAML parsing works with Ruby 2.7

# Development dependencies
group :development, :test do
  gem 'sqlite3'
  gem 'pry'
  gem 'pry-byebug'
  gem 'puma'
  gem 'rubocop-rails-omakase', require: false
  gem 'json-schema', require: false
end
