class AddBadRowSecurityExample < ActiveRecord::Migration[8.0]
  def change
    create_table :bad_row_security_examples do |t|
      t.string :name
      t.bigint :tenant_id
      t.timestamps
    end
  end
end
