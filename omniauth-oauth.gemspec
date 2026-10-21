require File.expand_path("../lib/omniauth-oauth/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Bleigh", "Erik Michaels-Ober"]
  gem.email         = ["michael@intridea.com", "sferik@gmail.com"]
  gem.description   = "A generic OAuth (1.0/1.0a) strategy for OmniAuth."
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/omniauth/omniauth-oauth"
  gem.license       = "MIT"

  gem.add_dependency "omniauth", ">= 1.0", "< 3"
  # oauth calls CGI.parse, which Ruby 4.0 moved out of the standard library.
  gem.add_dependency "cgi"
  gem.add_dependency "oauth"
  gem.add_dependency "rack", ">= 1.6.2", "< 4"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "omniauth-oauth"
  gem.required_ruby_version = ">= 2.5"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::OAuth::VERSION
end
