class AddTenantModel < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :key, null: false
      t.bigint :id_offset
      t.timestamps
    end

    add_index :tenants, :key, unique: true
  end
end
