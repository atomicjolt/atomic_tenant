module AtomicTenant
  class LtiDeployment < ApplicationRecord
    belongs_to :application_instance
  end
end
