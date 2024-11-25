AtomicTenant.jwt_secret = 'secret'.freeze
AtomicTenant.jwt_aud = 'aud'.freeze
AtomicTenant.admin_subdomain = 'admin'.freeze
AtomicTenant.tenants_table = :tenants

begin
  # This is NOT how you should set the db_tenant_restricted_user in production.
  # This is just a quick way to be able to test the gem in the dummy app.
  result = ActiveRecord::Base.connection.execute 'SELECT CURRENT_USER'
  AtomicTenant.db_tenant_restricted_user = result.first['current_user']
rescue ActiveRecord::NoDatabaseError
  # This is for the case where the database hasn't been created yet.
end
