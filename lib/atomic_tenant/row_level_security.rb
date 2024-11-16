module AtomicTenant::RowLevelSecurity
  def self.add_row_level_security(table_name)
    app_username = AtomicTenant.db_tenant_restricted_user

    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY"
    ActiveRecord::Base.connection.execute <<~SQL
      CREATE POLICY #{table_name}_tenanted_user
      ON #{table_name}
      TO #{app_username}
      USING (#{AtomicTenant.tenanted_by} = NULLIF(current_setting('rls.#{AtomicTenant.tenanted_by}', TRUE), '')::bigint)
    SQL
  end

  def self.remove_row_level_security(table_name)
    ActiveRecord::Base.connection.execute "DROP POLICY #{table_name}_tenanted_user ON #{table_name}"
    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} DISABLE ROW LEVEL SECURITY"
  end
end
