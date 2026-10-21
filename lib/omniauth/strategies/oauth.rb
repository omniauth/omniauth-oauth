require "oauth"
require "omniauth"

module OmniAuth
  module Strategies
    class OAuth
      include OmniAuth::Strategy

      args %i[consumer_key consumer_secret]
      option :consumer_key, nil
      option :consumer_secret, nil
      option :client_options, {}
      option :open_timeout, 30
      option :read_timeout, 30
      option :authorize_params, {}
      option :request_params, {}

      attr_reader :access_token

      def consumer
        consumer = ::OAuth::Consumer.new(options.consumer_key, options.consumer_secret, options.client_options)
        open_timeout = options.open_timeout
        read_timeout = options.read_timeout
        consumer.http.open_timeout = open_timeout if open_timeout
        consumer.http.read_timeout = read_timeout if read_timeout
        consumer
      end

      def request_phase
        request_token = consumer.get_request_token({:oauth_callback => callback_url}, options.request_params)
        session["oauth"] ||= {}
        session.fetch("oauth")[name.to_s] = {"callback_confirmed" => request_token.callback_confirmed?, "request_token" => request_token.token, "request_secret" => request_token.secret}

        if request_token.callback_confirmed?
          redirect request_token.authorize_url(options.authorize_params)
        else
          redirect request_token.authorize_url(options.authorize_params.merge(:oauth_callback => callback_url))
        end
      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
        fail!(:service_unavailable, e)
      end

      def callback_phase
        provider_session = (session["oauth"] || {})[name.to_s]
        raise(NoSessionError, "Session Expired") unless provider_session

        request_token = ::OAuth::RequestToken.new(consumer, provider_session.delete("request_token"), provider_session.delete("request_secret"))
        @access_token = request_token.get_access_token(access_token_options(provider_session))
        super
      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
        fail!(:service_unavailable, e)
      rescue ::OAuth::Unauthorized => e
        fail!(:invalid_credentials, e)
      rescue ::OmniAuth::NoSessionError => e
        fail!(:session_expired, e)
      end

      # The verifier when the provider confirmed the callback URL (OAuth
      # 1.0a), or the callback URL when it didn't (OAuth 1.0).
      def access_token_options(provider_session)
        if provider_session["callback_confirmed"]
          {:oauth_verifier => request.params["oauth_verifier"]}
        else
          {:oauth_callback => callback_url}
        end
      end

      credentials do
        {"token" => access_token.token, "secret" => access_token.secret}
      end

      extra do
        {"access_token" => access_token}
      end
    end
  end
end

OmniAuth.config.add_camelization "oauth", "OAuth"
