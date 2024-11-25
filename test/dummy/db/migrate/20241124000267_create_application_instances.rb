class CreateApplicationInstances < ActiveRecord::Migration[8.0]
  def change
    create_table :application_instances do |t|
      t.references :application, null: false, foreign_key: true
      t.string :lti_key

      t.timestamps
    end
  end
end
