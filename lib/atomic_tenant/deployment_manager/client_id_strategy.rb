require 'uri'

module AtomicTenant
  module DeploymentManager
      class ClientIdStrategy < DeploymentManagerStrategy
        def name
          'ClientIdStrategy'
        end

        def call(decoded_id_token:)
          client_id = AtomicLti::Lti.client_id(decoded_id_token)
          iss = decoded_id_token["iss"]

          if (pinned = AtomicTenant::PinnedClientId.find_by(iss: iss, client_id: client_id))
            DeploymentStrategyResult.new(application_instance_id: pinned.application_instance_id)
          else
            DeploymentStrategyResult.new()
          end
        end
      end
  end
end
