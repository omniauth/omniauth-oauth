source "http://rubygems.org"

gemspec

gem "rake"

# RuboCop 1.92 needs Ruby 2.7+, so older Rubies skip the rubocop task. Its
# Lint/MissingCopEnableDirective cop crashes on TruffleRuby, which skips it
# too.
gem "rubocop", "~> 1.92.0", :require => false if RUBY_VERSION >= "2.7" && RUBY_ENGINE != "truffleruby"

# Steep 2.1 needs Ruby 3.3+, so older Rubies skip the steep task. It checks
# against the types omniauth ships from 2.2.0 on.
if RUBY_VERSION >= "3.3"
  gem "omniauth", ">= 2.2"
  gem "steep", "~> 2.1", :require => false, :platforms => :mri
end

# Mutant needs Ruby 3.3+, so older Rubies skip the mutant task.
if RUBY_VERSION >= "3.3"
  gem "mutant", "~> 0.17.1", :platforms => :mri
  gem "mutant-rspec", "~> 0.17.1", :require => false, :platforms => :mri
end

group :test do
  gem "rack-test"
  gem "rspec", "~> 3.2"
  # SimpleCov 1.3 needs Ruby 3.3+, so older Rubies skip coverage.
  gem "simplecov", "~> 1.3", :require => false if RUBY_VERSION >= "3.3"
  gem "webmock"
end
