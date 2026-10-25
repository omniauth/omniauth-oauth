# frozen_string_literal: true

# Shared setup for the benchmarks: a strategy with fixed tokens, nonces
# and timestamps, an OAuth provider that never touches the network, and
# Rack envs built once and copied, with a fresh session, for each
# iteration.

require "rack/mock"

# Pin OmniAuth's global configuration, so no benchmark changes what
# another one sees. With no request validation, a request phase needs no
# CSRF token in its session.
OmniAuth.config.test_mode = false
OmniAuth.config.request_validation_phase = nil
OmniAuth.config.full_host = nil
OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.logger = Logger.new(File::NULL)

# The provider's answers, by host and path, built once. Net::HTTP never
# connects: each request gets its host's canned response back.
module DuelProvider
  def self.response(body)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, body.freeze)
    response.instance_variable_set(:@read, true)
    response
  end

  RESPONSES = {
    # OAuth 1.0a: the provider confirms the callback URL.
    "api.example.org/oauth/request_token" => response("oauth_token=requesttoken&oauth_token_secret=requestsecret&oauth_callback_confirmed=true"),
    "api.example.org/oauth/access_token" => response("oauth_token=accesstoken&oauth_token_secret=accesssecret&user_id=12345&screen_name=duel"),
    # OAuth 1.0: it doesn't.
    "legacy.example.org/oauth/request_token" => response("oauth_token=requesttoken&oauth_token_secret=requestsecret"),
    "legacy.example.org/oauth/access_token" => response("oauth_token=accesstoken&oauth_token_secret=accesssecret&user_id=12345&screen_name=duel"),
  }.freeze

  module HTTP
    def request(req, _body = nil)
      RESPONSES.fetch("#{address}#{req.path}")
    end
  end

  # A strategy as a gem would write one, on top of the generic one.
  class Strategy < OmniAuth::Strategies::OAuth
    uid { access_token.params[:user_id] }
    info { {"nickname" => access_token.params[:screen_name]} }
  end
end
Net::HTTP.prepend(DuelProvider::HTTP)

DUEL_INNER_APP = lambda { |_env| [200, {"content-type" => "text/plain"}.freeze, ["ok"].freeze] }

# The strategy as OmniAuth::Builder adds it. A fixed nonce and timestamp
# in the consumer's options make every request's signature the same.
def oauth_strategy(site: "https://api.example.org", **options)
  client_options = {:site => site, :nonce => "duelnonce", :timestamp => "1700000000"}
  DuelProvider::Strategy.new(DUEL_INNER_APP, "consumerkey", "consumersecret", :name => "example", :client_options => client_options, **options)
end

# The session that the request phase leaves for the callback phase.
def provider_session(callback_confirmed: true)
  {"oauth" => {"example" => {"callback_confirmed" => callback_confirmed, "request_token" => "requesttoken", "request_secret" => "requestsecret"}}}
end

# count copies of env, each with a fresh copy of session, for one
# sample's iterations.
def fresh_envs(count, env, session = {})
  Array.new(count) { env.merge("rack.session" => Marshal.load(Marshal.dump(session))) }
end

# Calls the app once with each env (the timed part of a sample).
def call_each(app, envs)
  envs.each { |env| app.call(env) }
end
