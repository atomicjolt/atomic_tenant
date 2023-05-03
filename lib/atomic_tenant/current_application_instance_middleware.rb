require_relative 'jwt_token'
require_relative 'exceptions'
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
          decoded_token = env['atomic.validated.decoded_id_token']
          iss = env['atomic.validated.decoded_id_token']['iss']
          deployment_id = env['atomic.validated.decoded_id_token'][AtomicLti::Definitions::DEPLOYMENT_ID]

          if deployment = AtomicTenant::LtiDeployment.find_by(iss: iss, deployment_id: deployment_id)
            env['atomic.validated.application_instance_id'] = deployment.application_instance_id
          else
            deployment = deployment_manager.link_deployment_id(decoded_id_token: decoded_token)
             env['atomic.validated.application_instance_id'] = deployment.application_instance_id
          end
        elsif env.dig("oauth_state", "application_instance_id").present?
          env['atomic.validated.application_instance_id'] = env["oauth_state"]["application_instance_id"]
        elsif is_admin?(request)
          admin_app_key = AtomicTenant.admin_subdomain
          admin_app = Application.find_by(key: admin_app_key)

          raise Exceptions::NoAdminApp if admin_app.nil?
          app_instances = admin_app.application_instances

          raise Exceptions::NonUniqueAdminApp if app_instances.count > 1
          raise Exceptions::NoAdminApp if app_instances.empty?

          if instance = app_instances.first
            env['atomic.validated.application_instance_id'] = instance.id
          end
        elsif encoded_token(request).present?
          token = encoded_token(request)
          # TODO: decoded token should be put on request
          decoded_token = AtomicTenant::JwtToken.decode(token)
          if decoded_token.present? && decoded_token.first.present?
            if app_instance_id = decoded_token.first['application_instance_id']
              env['atomic.validated.application_instance_id'] = app_instance_id
            end
          end

        end

      rescue StandardError => e
        Rails.logger.error("Error in current app instance middleware: #{e}, #{e.backtrace}")
      end

      @app.call(env)
    end

    def is_admin?(request)
      return true if request.path == "/readiness"

      host = request.host_with_port
      subdomain = host&.split(".")&.first

      return false if subdomain.nil?

      subdomain == AtomicTenant.admin_subdomain
    end

    def encoded_token(req)
      return req.params['jwt'] if req.params['jwt']

      # TODO: verify HTTP_AUTORIZAITON is the same as "Authorization"
      if header = req.get_header('HTTP_AUTHORIZATION') # || req.headers[:authorization]
        header.split(' ').last
      end
    end
  end
end
