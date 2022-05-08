require_relative 'jwt_token'
module AtomicTenant
  class CurrentApplicationInstanceMiddleware
    include JwtToken

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      if env['atomic.validated.oauth_consumer_key'].present?
        oauth_consumer_key = env['atomic.validated.oauth_consumer_key']
        if ai = ApplicationInstance.find_by(lti_key: oauth_consumer_key)
          env['atomic.validated.application_instance_id'] = ai.id
        end
      elsif encoded_token(request).present?
        token = encoded_token(request)

        # TODO: decoded token should be put on request
        # TODO AuthToken should live in a dep
        decoded_token = AuthToken.decode(token, nil, false)
        if decoded_token.present? && decoded_token.first.present?
          if app_instance_id = decoded_token.first['application_instance_id']
            env['atomic.validated.application_instance_id'] = app_instance_id
          end
        end
      end

      @app.call(env)
    end

    def encoded_token(req)
      return req.params[:jwt] if req.params[:jwt]

      # TODO: verify HTTP_AUTORIZAITON is the same as "Authorization"
      if header = req.get_header('HTTP_AUTHORIZATION') # || req.headers[:authorization]
        header.split(' ').last
      end
    end
  end
end
