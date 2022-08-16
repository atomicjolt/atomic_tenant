
class CreateAtomicTenantPinnedPlatformGuids < ActiveRecord::Migration[7.0]
  def change
    create_table :atomic_tenant_pinned_platform_guids do |t|
      t.string :platform_guid, null: false
      t.bigint :application_id, null: false

      t.bigint :application_instance_id, null: false

      t.timestamps
    end

    add_index :atomic_tenant_pinned_platform_guids, [:platform_guid, :application_id], unique: true, name: 'index_pinned_platform_guids'
  end
end
