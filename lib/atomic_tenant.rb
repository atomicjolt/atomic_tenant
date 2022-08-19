require 'atomic_tenant/version'
require 'atomic_tenant/deployment_manager/deployment_manager'
require 'atomic_tenant/deployment_manager/platform_guid_strategy'
require 'atomic_tenant/deployment_manager/client_id_strategy'
require 'atomic_tenant/deployment_manager/deployment_manager_strategy'
require 'atomic_tenant/engine'
require 'atomic_tenant/current_application_instance_middleware'

module AtomicTenant
  # Your code goes here...
  mattr_accessor :custom_strategies
end
