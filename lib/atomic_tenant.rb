require 'atomic_tenant/version'
require 'atomic_tenant/deployment_manager/deployment_manager'
require 'atomic_tenant/deployment_manager/platform_guid_strategy'
require 'atomic_tenant/deployment_manager/client_id_strategy'
require 'atomic_tenant/deployment_manager/deployment_manager_strategy'
require 'atomic_tenant/engine'
require 'atomic_tenant/current_application_instance_middleware'

module AtomicTenant
  mattr_accessor :custom_strategies

  mattr_accessor :jwt_secret
  mattr_accessor :jwt_aud

  mattr_accessor :admin_subdomain


  def self.get_application_instance(iss:, deployment_id:)
    AtomicTenant::LtiDeployment.find_by(iss: iss, deployment_id: deployment_id)
  end
end
