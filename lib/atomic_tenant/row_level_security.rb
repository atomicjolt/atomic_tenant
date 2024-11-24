module AtomicTenant::RowLevelSecurity
  def self.add_row_level_security(table_name)
    app_username = ActiveRecord::Base.connection.quote_column_name(AtomicTenant.db_tenant_restricted_user)
    safe_table_name = ActiveRecord::Base.connection.quote_table_name(table_name)
    policy_name = ActiveRecord::Base.connection.quote_table_name("#{table_name}_tenanted_user")
    rls_setting_name = ActiveRecord::Base.connection.quote("rls.#{AtomicTenant.tenanted_by}")
    tenanted_by = ActiveRecord::Base.connection.quote_column_name(AtomicTenant.tenanted_by)

    ActiveRecord::Base.connection.execute("ALTER TABLE #{safe_table_name} ENABLE ROW LEVEL SECURITY")
    ActiveRecord::Base.connection.execute <<~SQL
      CREATE POLICY #{policy_name}
      ON #{safe_table_name}
      TO #{app_username}
      USING (#{tenanted_by} = NULLIF(current_setting(#{rls_setting_name}, TRUE), '')::bigint)
    SQL
  end

  def self.remove_row_level_security(table_name)
    safe_table_name = ActiveRecord::Base.connection.quote_table_name(table_name)
    policy_name = ActiveRecord::Base.connection.quote_table_name("#{table_name}_tenanted_user")
    ActiveRecord::Base.connection.execute("DROP POLICY #{policy_name} ON #{safe_table_name}")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{safe_table_name} DISABLE ROW LEVEL SECURITY")
  end
end
