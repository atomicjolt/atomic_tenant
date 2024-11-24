class AddGoodRowSecurityExample < ActiveRecord::Migration[8.0]
  def change
    create_table :good_row_security_examples do |t|
      t.string :name
      t.bigint :tenant_id
      t.timestamps
    end

    AtomicTenant::RowLevelSecurity.add_row_level_security(:good_row_security_examples)
  end
end
