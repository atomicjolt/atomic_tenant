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
  end
end