class CreateAtomicTenantTenantModel < ActiveRecord::Migration[7.0]
  def change
    create_table :atomic_tenant_tenants do |t|
      t.string :key, null: false
      t.bigint :id_offset
    end

    add_index :atomic_tenant_tenants, :key, unique: true
  end
end
