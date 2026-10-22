require File.expand_path("lib/omniauth-oauth/version", __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ["Erik Berlin", "Michael Bleigh"]
  gem.email         = ["sferik@gmail.com", "michael@intridea.com"]
  gem.description   = "A generic OAuth (1.0/1.0a) strategy for OmniAuth."
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/omniauth/omniauth-oauth"
  gem.license       = "MIT"

  gem.add_dependency "omniauth", "~> 2.3", ">= 2.3.1"
  # oauth calls CGI.parse, which Ruby 4.0 moved out of the standard library.
  gem.add_dependency "cgi"
  gem.add_dependency "oauth"
  gem.add_dependency "rack", ">= 1.6.2", "< 4"

  gem.files         = Dir["lib/**/*", "sig/**/*.rbs", "LICENSE.md", "README.md"]
  gem.name          = "omniauth-oauth"
  gem.required_ruby_version = ">= 2.5"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::OAuth::VERSION
  gem.metadata["changelog_uri"] = "#{gem.homepage}/blob/master/CHANGELOG.md"
  gem.metadata["rubygems_mfa_required"] = "true"
end
