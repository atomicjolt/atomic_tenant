module AtomicTenant::RowLevelSecurity
  def self.add_row_level_security(table_name)
    db_configs = Rails.configuration.database_configuration[Rails.env]
    app_username = db_configs["primary"]["username"]

    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY"
    ActiveRecord::Base.connection.execute "CREATE POLICY #{table_name}_app_user ON #{table_name} TO #{app_username} USING (tenant_id = NULLIF(current_setting('rls.tenant_id', TRUE), '')::bigint)"
  end

  def self.remove_row_level_security(table_name)
    ActiveRecord::Base.connection.execute "DROP POLICY #{table_name}_app_user ON #{table_name}"
    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} DISABLE ROW LEVEL SECURITY"
  end
end
