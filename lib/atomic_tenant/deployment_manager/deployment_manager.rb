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
        def call(id_token:); end
      end



    # Associate deployment
    class DeploymentManager

        def initialize(strageties)
            @strageties = strageties || []
        end

        def link_deployment_id(id_token:)
          decoded_token = JWT.decode(id_token, nil, false)
          deployment_id = decoded_token.dig(0, AtomicLti::Definitions::DEPLOYMENT_ID)
          iss = decoded_token.dig(0, "iss")


          results = @strageties.map do |strategy| 
            {name: strategy.name, result: strategy.call(id_token: id_token)}
          end

          matched = results.filter { |r| r[:result].app_instance_id.present? }

          to_link = if matched.size == 1
                      matched.first
                    elsif matched.size > 1
                      matched.first
                      # TODO report

                    else
                      raise Exceptions::UnableToLinkDeploymentError
                    end

          Rails.logger.debug("Linking iss / deployment id: #{iss} / #{deployment_id} to application instance: #{to_link.application_instance_idl}")

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