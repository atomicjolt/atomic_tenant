class AddAtomicTenantLtiDeploymentPlatformNotificationStatus < ActiveRecord::Migration[7.1]
  def change
    add_column :atomic_tenant_lti_deployments, :registered_pns_notifications_at, :timestamptz
  end
end
