require_relative 'jwt_token'
module AtomicTenant
  class CurrentApplicationInstanceMiddleware
    include JwtToken

    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        request = Rack::Request.new(env)

        if env['atomic.validated.oauth_consumer_key'].present?
          oauth_consumer_key = env['atomic.validated.oauth_consumer_key']
          if ai = ApplicationInstance.find_by(lti_key: oauth_consumer_key)
            env['atomic.validated.application_instance_id'] = ai.id
          end
        elsif env['atomic.validated.id_token'].present?

          custom_strategies = AtomicTenant.custom_strategies || []
          default_strategies = [
            AtomicTenant::DeploymentManager::PlatformGuidStrategy.new,
            AtomicTenant::DeploymentManager::ClientIdStrategy.new
          ]

          deployment_manager = AtomicTenant::DeploymentManager::DeploymentManager.new(custom_strategies.concat(default_strategies))
          iss = env['atomic.validated.decoded_id_token']['iss']
          deployment_id = env['atomic.validated.decoded_id_token'][AtomicLti::Definitions::DEPLOYMENT_ID]
          id_token = env['atomic.validated.id_token']

          if deployment = AtomicTenant::LtiDeployment.find_by(iss: iss, deployment_id: deployment_id)
            env['atomic.validated.application_instance_id'] = deployment.application_instance_id
          else
            deployment = deployment_manager.link_deployment_id(id_token: id_token)
             env['atomic.validated.application_instance_id'] = deployment.application_instance_id
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

      rescue StandardError => e
        Rails.logger.error("Error in current app instance middleware: #{e}")
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
