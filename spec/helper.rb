$LOAD_PATH.unshift File.expand_path("..", __FILE__)
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
# Coverage is measured on CRuby 3.3+ only. SimpleCov 1.3 needs Ruby 3.3,
# and JRuby and TruffleRuby count lines differently. Mutant runs the specs
# against mutated code, so coverage is skipped there too.
if RUBY_ENGINE == "ruby" && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.3") && !defined?(Mutant)
  require "simplecov"
  SimpleCov.start "strict"
end
require "rspec"
require "rack/test"
require "webmock/rspec"
require "omniauth"
require "omniauth-oauth"

OmniAuth.config.request_validation_phase = nil

RSpec.configure do |config|
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, :type => :strategy
end

OmniAuth.config.logger = Logger.new("/dev/null")
