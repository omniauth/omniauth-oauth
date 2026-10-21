require "helper"

class MyOAuthProvider < OmniAuth::Strategies::OAuth
  uid { access_token.token }
  info { {"name" => access_token.token} }
end

describe "OmniAuth::Strategies::OAuth" do
  def app
    Rack::Builder.new do
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider MyOAuthProvider, "abc", "def", :client_options => {:site => "https://api.example.org"}, :name => "example.org"
        provider MyOAuthProvider, "abc", "def", :client_options => {:site => "https://api.example.org"}, :authorize_params => {:abc => "def"}, :name => "example.org_with_authorize_params"
        provider MyOAuthProvider, "abc", "def", :client_options => {:site => "https://api.example.org"}, :request_params => {:scope => "http://foobar.example.org"}, :name => "example.org_with_request_params"
        provider MyOAuthProvider, "abc", "def", :client_options => {:site => "https://api.example.org"}, :name => :symbol_name
      end
      run lambda { |env| [404, {"Content-Type" => "text/plain"}, [env.key?("omniauth.auth").to_s]] }
    end.to_app
  end

  def session
    last_request.env["rack.session"]
  end

  before do
    stub_request(:post, "https://api.example.org/oauth/request_token").
      to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret&oauth_callback_confirmed=true")
  end

  it "should add a camelization for itself" do
    expect(OmniAuth::Utils.camelize("oauth")).to eq("OAuth")
  end

  describe "/auth/{name}" do
    context "successful" do
      before do
        post "/auth/example.org"
      end

      it "should redirect to authorize_url" do
        expect(last_response).to be_redirect
        expect(last_response.headers["Location"]).to eq("https://api.example.org/oauth/authorize?oauth_token=yourtoken")
      end

      it "should redirect to authorize_url with authorize_params when set" do
        post "/auth/example.org_with_authorize_params"
        expect(last_response).to be_redirect
        expect([
                 "https://api.example.org/oauth/authorize?abc=def&oauth_token=yourtoken",
                 "https://api.example.org/oauth/authorize?oauth_token=yourtoken&abc=def",
               ]).to be_include(last_response.headers["Location"])
      end

      it "should set appropriate session variables" do
        expect(session["oauth"]).to eq("example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"})
      end

      it "should pass request_params to get_request_token" do
        post "/auth/example.org_with_request_params"
        expect(WebMock).to(have_requested(:post, "https://api.example.org/oauth/request_token").
          with { |req| req.body == "scope=http%3A%2F%2Ffoobar.example.org" })
      end
    end

    context "unsuccessful" do
      before do
        stub_request(:post, "https://api.example.org/oauth/request_token").
          to_raise(Net::HTTPFatalError.new('502 "Bad Gateway"', nil))
        post "/auth/example.org"
      end

      it "should call fail! with :service_unavailable" do
        expect(last_request.env["omniauth.error"]).to be_kind_of(Net::HTTPFatalError)
        expect(last_request.env["omniauth.error.type"]).to eq(:service_unavailable)
      end

      context "SSL failure" do
        before do
          stub_request(:post, "https://api.example.org/oauth/request_token").
            to_raise(OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))
          post "/auth/example.org"
        end

        it "should call fail! with :service_unavailable" do
          expect(last_request.env["omniauth.error"]).to be_kind_of(OpenSSL::SSL::SSLError)
          expect(last_request.env["omniauth.error.type"]).to eq(:service_unavailable)
        end
      end
    end
  end

  describe "/auth/{name}/callback" do
    before do
      stub_request(:post, "https://api.example.org/oauth/access_token").
        to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
    end

    it "should exchange the request token for an access token" do
      expect(last_request.env["omniauth.auth"]["provider"]).to eq("example.org")
      expect(last_request.env["omniauth.auth"]["extra"]["access_token"]).to be_kind_of(OAuth::AccessToken)
    end

    it "should call through to the master app" do
      expect(last_response.body).to eq("true")
    end

    context "bad gateway (or any 5xx) for access_token" do
      before do
        stub_request(:post, "https://api.example.org/oauth/access_token").
          to_raise(Net::HTTPFatalError.new('502 "Bad Gateway"', nil))
        get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
      end

      it "should call fail! with :service_unavailable" do
        expect(last_request.env["omniauth.error"]).to be_kind_of(Net::HTTPFatalError)
        expect(last_request.env["omniauth.error.type"]).to eq(:service_unavailable)
      end
    end

    context "SSL failure" do
      before do
        stub_request(:post, "https://api.example.org/oauth/access_token").
          to_raise(OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))
        get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
      end

      it "should call fail! with :service_unavailable" do
        expect(last_request.env["omniauth.error"]).to be_kind_of(OpenSSL::SSL::SSLError)
        expect(last_request.env["omniauth.error.type"]).to eq(:service_unavailable)
      end
    end
  end

  describe "/auth/{name}/callback with Rack 2.x and 3.x" do
    before do
      stub_request(:post, "https://api.example.org/oauth/access_token").
        to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
    end

    context "Rack 2.x style request" do
      before do
        get "/auth/example.org/callback", {"oauth_verifier" => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
      end

      it "should exchange the request token for an access token" do
        expect(last_request.env["omniauth.auth"]["provider"]).to eq("example.org")
        expect(last_request.env["omniauth.auth"]["extra"]["access_token"]).to be_kind_of(OAuth::AccessToken)
      end

      it "should call through to the master app" do
        expect(last_response.body).to eq("true")
      end
    end

    context "Rack 3.x style request" do
      before do
        # Simulate Rack 3.x behavior by putting oauth_verifier in the params
        allow_any_instance_of(Rack::Request).to receive(:params).and_return({"oauth_verifier" => "dudeman"})
        get "/auth/example.org/callback", {}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
      end

      it "should exchange the request token for an access token" do
        expect(last_request.env["omniauth.auth"]["provider"]).to eq("example.org")
        expect(last_request.env["omniauth.auth"]["extra"]["access_token"]).to be_kind_of(OAuth::AccessToken)
      end

      it "should call through to the master app" do
        expect(last_response.body).to eq("true")
      end
    end
  end

  describe "/auth/{name}/callback with expired session" do
    before do
      stub_request(:post, "https://api.example.org/oauth/access_token").
        to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {}
    end

    it "should call fail! with :session_expired" do
      expect(last_request.env["omniauth.error"]).to be_kind_of(OmniAuth::NoSessionError)
      expect(last_request.env["omniauth.error.type"]).to eq(:session_expired)
    end
  end

  describe "#consumer" do
    it "sets the HTTP timeouts from the options" do
      http = MyOAuthProvider.new(nil, "abc", "def", :open_timeout => 5, :read_timeout => 10).consumer.http
      expect([http.open_timeout, http.read_timeout]).to eq([5, 10])
    end

    it "keeps Net::HTTP's default timeouts when the options are nil" do
      http = MyOAuthProvider.new(nil, "abc", "def", :open_timeout => nil, :read_timeout => nil).consumer.http
      expect([http.open_timeout, http.read_timeout]).to eq([Net::HTTP.new("example.org").open_timeout, Net::HTTP.new("example.org").read_timeout])
    end
  end

  describe "/auth/{name} when the provider doesn't confirm the callback" do
    before do
      stub_request(:post, "https://api.example.org/oauth/request_token").
        to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      post "/auth/example.org"
    end

    it "sends the callback URL in the authorize URL" do
      location = URI.parse(last_response.headers["Location"])
      expect(Rack::Utils.parse_query(location.query)).to eq("oauth_token" => "yourtoken", "oauth_callback" => "http://example.org/auth/example.org/callback")
    end

    it "remembers that the callback wasn't confirmed" do
      expect(session["oauth"]["example.org"]["callback_confirmed"]).to be(false)
    end
  end

  describe "/auth/{name} timeout" do
    before do
      stub_request(:post, "https://api.example.org/oauth/request_token").to_timeout
      post "/auth/example.org"
    end

    it "should call fail! with :timeout" do
      expect(last_request.env["omniauth.error"]).to be_kind_of(Timeout::Error)
      expect(last_request.env["omniauth.error.type"]).to eq(:timeout)
    end
  end

  describe "/auth/{name}/callback when the provider didn't confirm the callback" do
    before do
      stub_request(:post, "https://api.example.org/oauth/access_token").
        to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => false, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
    end

    it "sends the callback URL instead of the verifier" do
      expect(WebMock).to(have_requested(:post, "https://api.example.org/oauth/access_token").with { |req| req.headers["Authorization"].include?("oauth_callback=") && !req.headers["Authorization"].include?("oauth_verifier=") })
      expect(last_request.env["omniauth.auth"]["provider"]).to eq("example.org")
    end
  end

  describe "/auth/{name}/callback errors" do
    def callback
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
    end

    it "calls fail! with :timeout when the access token request times out" do
      stub_request(:post, "https://api.example.org/oauth/access_token").to_timeout
      callback
      expect(last_request.env["omniauth.error"]).to be_kind_of(Timeout::Error)
      expect(last_request.env["omniauth.error.type"]).to eq(:timeout)
    end

    it "calls fail! with :invalid_credentials when the provider rejects the request token" do
      stub_request(:post, "https://api.example.org/oauth/access_token").to_return(:status => 401, :body => "invalid token")
      callback
      expect(last_request.env["omniauth.error"]).to be_kind_of(OAuth::Unauthorized)
      expect(last_request.env["omniauth.error.type"]).to eq(:invalid_credentials)
    end
  end

  describe "signed requests" do
    # The params of the request's OAuth Authorization header.
    def oauth_params(request)
      request.headers["Authorization"].sub(/\AOAuth /, "").split(/,\s*/).map do |pair|
        key, value = pair.split("=", 2)
        [key, URI.decode_www_form_component(value.delete('"'))]
      end.to_h
    end

    def oauth_escape(value)
      value.to_s.b.gsub(/[^A-Za-z0-9\-._~]/) { |char| format("%%%02X", char.ord) }
    end

    # Checks the request's HMAC-SHA1 signature independently of the oauth
    # gem, following https://www.rfc-editor.org/rfc/rfc5849#section-3.4.
    def signed_with?(request, consumer_secret, token_secret)
      params = oauth_params(request)
      signature = params.delete("oauth_signature")
      body_params = request.headers["Content-Type"].to_s.start_with?("application/x-www-form-urlencoded") ? URI.decode_www_form(request.body.to_s) : []
      normalized = (params.to_a + body_params).map { |key, value| [oauth_escape(key), oauth_escape(value)] }.sort.map { |pair| pair.join("=") }.join("&")
      url = "#{request.uri.scheme}://#{request.uri.host}#{request.uri.path}"
      base = [request.method.to_s.upcase, oauth_escape(url), oauth_escape(normalized)].join("&")
      key = "#{oauth_escape(consumer_secret)}&#{oauth_escape(token_secret)}"
      signature == [OpenSSL::HMAC.digest("SHA1", key, base)].pack("m0")
    end

    def confirmed_session(name = "example.org")
      {"oauth" => {name => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
    end

    def requests_to(path)
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys.select { |request| request.uri.path == path }
    end

    def access_token_request
      requests = requests_to("/oauth/access_token")
      expect(requests.size).to eq(1)
      requests.first
    end

    before do
      stub_request(:post, "https://api.example.org/oauth/access_token").
        to_return(:body => "oauth_token=youraccesstoken&oauth_token_secret=youraccesssecret")
    end

    it "signs the request token request with the consumer key and secret and sends the callback URL" do
      post "/auth/example.org"
      request = requests_to("/oauth/request_token").first
      expect(oauth_params(request)).to include("oauth_consumer_key" => "abc", "oauth_callback" => "http://example.org/auth/example.org/callback")
      expect(oauth_params(request)).not_to have_key("oauth_token")
      expect(signed_with?(request, "def", "")).to be(true)
    end

    it "signs the access token request with the request token and sends the verifier" do
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => confirmed_session
      params = oauth_params(access_token_request)
      expect(params).to include("oauth_consumer_key" => "abc", "oauth_token" => "yourtoken", "oauth_verifier" => "dudeman")
      expect(params).not_to have_key("oauth_callback")
      expect(signed_with?(access_token_request, "def", "yoursecret")).to be(true)
      expect(last_request.env["omniauth.auth"]["uid"]).to eq("youraccesstoken")
    end

    it "sends the callback URL, with its query string, when the provider didn't confirm the callback" do
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"callback_confirmed" => false, "request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
      params = oauth_params(access_token_request)
      expect(params).to include("oauth_token" => "yourtoken", "oauth_callback" => "http://example.org/auth/example.org/callback?oauth_verifier=dudeman")
      expect(params).not_to have_key("oauth_verifier")
      expect(signed_with?(access_token_request, "def", "yoursecret")).to be(true)
    end

    it "sends the callback URL when the session doesn't say whether the callback was confirmed" do
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {"oauth" => {"example.org" => {"request_token" => "yourtoken", "request_secret" => "yoursecret"}}}
      expect(oauth_params(access_token_request)).to include("oauth_callback" => "http://example.org/auth/example.org/callback?oauth_verifier=dudeman")
    end

    it "omits the verifier when the callback has none" do
      get "/auth/example.org/callback", {}, "rack.session" => confirmed_session
      expect(oauth_params(access_token_request)).not_to have_key("oauth_verifier")
      expect(last_request.env["omniauth.auth"]["uid"]).to eq("youraccesstoken")
    end

    it "removes the request token and secret from the session" do
      session = confirmed_session
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => session
      expect(last_request.env["rack.session"]["oauth"]).to eq("example.org" => {"callback_confirmed" => true})
    end

    it "keys the session by the name as a string when the name is a symbol" do
      post "/auth/symbol_name"
      expect(last_request.env["rack.session"]["oauth"]).to eq("symbol_name" => {"callback_confirmed" => true, "request_token" => "yourtoken", "request_secret" => "yoursecret"})
    end

    it "finds the session by the name as a string when the name is a symbol" do
      get "/auth/symbol_name/callback", {:oauth_verifier => "dudeman"}, "rack.session" => confirmed_session("symbol_name")
      expect(oauth_params(access_token_request)).to include("oauth_token" => "yourtoken")
      expect(last_request.env["omniauth.auth"]["provider"]).to eq(:symbol_name)
    end

    it "fails with :session_expired and a message when there's no OAuth session" do
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => {}
      expect(last_request.env["omniauth.error"]).to be_a(OmniAuth::NoSessionError)
      expect(last_request.env["omniauth.error"].message).to eq("Session Expired")
      expect(last_request.env["omniauth.error.type"]).to eq(:session_expired)
      expect(requests_to("/oauth/access_token")).to be_empty
    end

    it "fails with :session_expired when the OAuth session belongs to another provider" do
      get "/auth/example.org/callback", {:oauth_verifier => "dudeman"}, "rack.session" => confirmed_session("other")
      expect(last_request.env["omniauth.error"]).to be_a(OmniAuth::NoSessionError)
      expect(last_request.env["omniauth.error.type"]).to eq(:session_expired)
    end
  end
end
