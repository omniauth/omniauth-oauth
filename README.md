# OmniAuth OAuth

This gem contains a generic OAuth strategy for OmniAuth. It is meant to
serve as a building block strategy for other strategies and not to be
used independently (since it has no inherent way to gather uid and user
info).

## Creating an OAuth Strategy

To create an OmniAuth OAuth strategy using this gem, you can simply
subclass it and add a few extra methods like so:

    require 'omniauth-oauth'

    module OmniAuth
      module Strategies
        class SomeSite
          # Give your strategy a name.
          option :name, "some_site"

          # This is where you pass the options you would pass when
          # initializing your consumer from the OAuth gem.
          option :client_options, {:site => "https://api.somesite.com"}

          # This is called after authentication has succeeded. If
          # possible, you should try to set the UID without making
          # additional calls (if the user id is returned with the token
          # or as a URI parameter). This may not be possible with all
          # providers.
          def uid
            request.params['user_id']
          end

          # This is called after authentication has succeeded. You can
          # make signed API requests by using the #access_token method
          # which is simply an OAuth gem AccessToken object.
          def info
            {
              :name => raw_info['name'],
              :location => raw_info['city']
            }
          end

          def extra
            super.merge({
              'raw_info' => raw_info
            })
          end

          def raw_info
            @raw_info ||= MultiJson.decode(access_token.get('/me.json')).body
          end
        end
      end
    end

That's pretty much it! Once you are successfully 
