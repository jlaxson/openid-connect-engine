module Connect
  class TokenEndpoint
    attr_accessor :app
    delegate :call, to: :app

    def initialize
      @app = Rack::OAuth2::Server::Token.new do |req, res|
        client = Client.find_by(identifier: req.client_id) || req.invalid_client!
        client.secret == req.client_secret || req.invalid_client!
        case req.grant_type
        when :client_credentials
          res.access_token = client.access_tokens.create!.to_bearer_token
        when :authorization_code
          authorization = client.authorizations.valid.find_by(code: req.code)
          req.invalid_grant! if authorization.blank? || !authorization.valid_redirect_uri?(req.redirect_uri)
          access_token = authorization.access_token
          res.access_token = access_token.to_bearer_token
          if access_token.accessible?(Scope::OPENID)
            res.id_token = IdToken.create!(
              account: access_token.account,
              client: access_token.client,
              nonce: authorization.nonce,
              request_object: authorization.request_object
            ).to_response_object(access_token: res.access_token).to_jwt IdToken.config[:private_key]
          end
        else
          req.unsupported_grant_type!
        end
      end
    end
  end
end
