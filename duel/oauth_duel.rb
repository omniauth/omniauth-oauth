# frozen_string_literal: true

# Benchmarks of OmniAuth::Strategies::OAuth, called directly as Rack
# middleware. The strategy sits in every request's middleware stack, so
# its pass-through for requests that aren't for it runs on every request.
# Its request and callback phases run once per sign-in: they build the
# consumer, sign a token request (to a provider that never touches the
# network), and redirect or build the AuthHash.

require_relative "duel_helper"

duel "passthrough: a GET to another path" do |n|
  once do
    @app = oauth_strategy
    @env = Rack::MockRequest.env_for("https://www.example.com/posts/42?page=2", :method => "GET")
  end
  envs = untimed { fresh_envs(n, @env) }
  call_each(@app, envs)
end

duel "passthrough: a POST to another provider" do |n|
  once do
    @app = oauth_strategy
    @env = Rack::MockRequest.env_for("https://www.example.com/auth/other", :method => "POST")
  end
  envs = untimed { fresh_envs(n, @env) }
  call_each(@app, envs)
end

duel "request: OAuth 1.0a, callback confirmed" do |n|
  once do
    @app = oauth_strategy
    @env = Rack::MockRequest.env_for("https://www.example.com/auth/example", :method => "POST")
  end
  envs = untimed { fresh_envs(n, @env) }
  call_each(@app, envs)
end

duel "request: OAuth 1.0, callback unconfirmed" do |n|
  once do
    @app = oauth_strategy(:site => "https://legacy.example.org")
    @env = Rack::MockRequest.env_for("https://www.example.com/auth/example", :method => "POST")
  end
  envs = untimed { fresh_envs(n, @env) }
  call_each(@app, envs)
end

duel "request: with request and authorize params" do |n|
  once do
    @app = oauth_strategy(
      :request_params => {:scope => "read write", :x_auth_access_type => "read"},
      :authorize_params => {:force_login => "true", :screen_name => "duel"},
    )
    @env = Rack::MockRequest.env_for("https://www.example.com/auth/example", :method => "POST")
  end
  envs = untimed { fresh_envs(n, @env) }
  call_each(@app, envs)
end

duel "callback: OAuth 1.0a, with a verifier" do |n|
  once do
    @app = oauth_strategy
    @env = Rack::MockRequest.env_for("https://www.example.com/auth/example/callback?oauth_token=requesttoken&oauth_verifier=verifier", :method => "GET")
    @session = provider_session
  end
  envs = untimed { fresh_envs(n, @env, @session) }
  call_each(@app, envs)
end

duel "callback: OAuth 1.0, callback unconfirmed" do |n|
  once do
    @app = oauth_strategy(:site => "https://legacy.example.org")
    @env = Rack::MockRequest.env_for("https://www.example.com/auth/example/callback?oauth_token=requesttoken", :method => "GET")
    @session = provider_session(:callback_confirmed => false)
  end
  envs = untimed { fresh_envs(n, @env, @session) }
  call_each(@app, envs)
end
