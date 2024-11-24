module AtomicTenant::TenantSwitching
  extend ActiveSupport::Concern

  included do
    validates :key, presence: true, uniqueness: true

    def self.switch!(tenant = nil)
      if tenant
        connection.clear_query_cache
        Thread.current[:tenant] = tenant

        variable = ActiveRecord::Base.connection.quote_column_name("rls.#{AtomicTenant.tenanted_by}")
        query = "SET #{variable} = %s"
        ActiveRecord::Base.connection.exec_query(query % connection.quote(tenant.id), 'SQL')
      else
        reset!
      end
    end

    def self.reset!
      connection.clear_query_cache
      Thread.current[:tenant] = nil

      variable = ActiveRecord::Base.connection.quote_column_name("rls.#{AtomicTenant.tenanted_by}")
      query = "RESET #{variable}"
      ActiveRecord::Base.connection.exec_query(query, 'SQL')
    end

    def self.switch_tenant_legacy!(tenant_key = nil)
      if tenant_key
        tenant = tenant_from_key!(tenant_key)
        switch!(tenant)
      else
        reset!
      end
    end

    def self.current_key
      Thread.current[:tenant]&.key || 'public'
    end

    def self.current
      Thread.current[:tenant]
    end

    def self.switch_tenant_legacy(tenant_key, &block)
      tenant = tenant_from_key!(tenant_key)
      switch(tenant, &block)
    end

    def self.tenant_from_key!(tenant_key)
      tenant = AtomicTenant.tenant_model.find_by(key: tenant_key)
      raise AtomicTenant::Exceptions::InvalidTenantKeyError, tenant_key unless tenant.present?

      tenant
    end

    def self.switch(tenant, &block)
      previous_tenant = Thread.current[:tenant]

      begin
        switch!(tenant)
        block.call
      ensure
        if previous_tenant.present?
          switch!(previous_tenant)
        else
          reset!
        end
      end
    end
  end
end
