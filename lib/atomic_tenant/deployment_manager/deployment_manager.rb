module AtomicTenant

  module DeploymentManager
      class DeploymentStrategyResult
        attr_accessor :application_instance_id
        attr_accessor :details

        def initialize(application_instance_id: nil, details: nil)
          @application_instance_id = application_instance_id
          @details = details
        end

      end

      class DeploymentManagerStrategy
        def name; end
        def call(decoded_id_token:); end
      end



    # Associate deployment
    class DeploymentManager

        def initialize(strageties)
            @strageties = strageties || []
        end

        def link_deployment_id(decoded_id_token:)
          deployment_id = decoded_id_token[AtomicLti::Definitions::DEPLOYMENT_ID]
          iss = decoded_id_token["iss"]

          results = @strageties.flat_map do |strategy|
            begin
              [{name: strategy.name, result: strategy.call(decoded_id_token: decoded_id_token)}]
            rescue StandardError => e
               Rails.logger.error("Error in lti deployment linking strategy: #{strategy.name}, #{e}")
              []
            end
          end

          Rails.logger.debug("Linking Results: #{results}")

          matched = results.filter { |r| r[:result].application_instance_id.present? }

          to_link = if matched.size == 1
                      matched.first[:result]
                    elsif matched.size > 1
                      matched.first[:result]
                      Rails.logger.info("Colliding strategies, Linking iss / deployment id: #{iss} / #{deployment_id} to application instance: #{to_link.application_instance_id}, all results: #{results}")

                    else
                      raise AtomicTenant::Exceptions::UnableToLinkDeploymentError
                    end

          Rails.logger.info("Linking iss / deployment id: #{iss} / #{deployment_id} to application instance: #{to_link.application_instance_id}")

          associate_deployment(iss: iss, deployment_id: deployment_id,application_instance_id: to_link.application_instance_id)
        end

        private

        def associate_deployment(iss:, deployment_id:, application_instance_id:)
          AtomicTenant::LtiDeployment.create!(
            iss: iss,
            deployment_id: deployment_id,
            application_instance_id: application_instance_id
          )
        end
    end
  end
end
