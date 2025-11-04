module AtomicTenant

  module DeploymentManager
    class DeploymentStrategyResult
      attr_accessor :application_instance_id, :details

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

        to_link = nil
        strategy_name = nil

        @strageties.each do |strategy|
          result = strategy.call(decoded_id_token: decoded_id_token)
          if result.application_instance_id.present?
            to_link = result
            strategy_name = strategy.name
            break
          end
        rescue StandardError => e
          Rails.logger.error("Error in lti deployment linking strategy: #{strategy.name}, #{e}")
        end

        raise AtomicTenant::Exceptions::UnableToLinkDeploymentError if to_link.nil?

        Rails.logger.info(
          "Linking iss / deployment id: #{iss} / #{deployment_id} to application instance: " \
          "#{to_link.application_instance_id} using strategy: #{strategy_name}"
        )

        associate_deployment(
          iss: iss,
          deployment_id: deployment_id,
          application_instance_id: to_link.application_instance_id
        )
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
