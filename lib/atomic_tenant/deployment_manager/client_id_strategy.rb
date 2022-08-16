require 'uri'

module AtomicTenant
  module DeploymentManager
      class ClientIdStrategy < DeploymentManagerStrategy
        def name
          'ClientIdStrategy'
        end

        def call(id_token:)
          decoded_token = JWT.decode(id_token, nil, false)
          client_id = decoded_token[0]["aud"]
          iss = decoded_token[0]["iss"]

          if (pinned = AtomicTenant::PinnedClientId.find_by(iss: iss, client_id: client_id))
            DeploymentStrategyResult.new(application_instance_id: pinned.application_instance_id)
          else
            DeploymentStrategyResult.new()
          end
        end
      end
  end
end