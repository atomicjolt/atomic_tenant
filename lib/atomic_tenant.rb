require 'atomic_tenant/version'
require 'atomic_tenant/deployment_manager/deployment_manager'
require 'atomic_tenant/deployment_manager/platform_guid_strategy'
require 'atomic_tenant/deployment_manager/client_id_strategy'
require 'atomic_tenant/deployment_manager/deployment_manager_strategy'
require 'atomic_tenant/deployment_manager/abstract_auto_create_platform_guid_strategy'
require 'atomic_tenant/engine'
require 'atomic_tenant/current_application_instance_middleware'
require 'atomic_tenant/tenant_switching'
require 'atomic_tenant/row_level_security'
require 'atomic_tenant/tenantable'
require 'atomic_tenant/active_job'

module AtomicTenant
  mattr_accessor :custom_strategies
  mattr_accessor :custom_fallback_strategies

  mattr_accessor :untrusted_iss_tenant_limit, default: 100
  mattr_accessor :tenant_uuid_namespace

  mattr_accessor :jwt_secret
  mattr_accessor :jwt_aud

  mattr_accessor :admin_subdomain
  mattr_accessor :tenants_table
  mattr_accessor :db_tenant_restricted_user

  def self.get_application_instance(iss:, deployment_id:)
    AtomicTenant::LtiDeployment.find_by(iss: iss, deployment_id: deployment_id)
  end

  def self.tenant_model
    AtomicTenant.tenants_table.to_s.classify.constantize
  end

  def self.tenanted_by
    "#{AtomicTenant.tenants_table.to_s.singularize}_id"
  end
end
