module AtomicTenant
  class Tenant < ActiveRecord::Base
    has_many :application_instances

    SET_TENANT_ID_SQL = 'SET rls.tenant_id = %s'.freeze
    RESET_TENANT_ID_SQL = 'RESET rls.tenant_id'.freeze

    def promise(association_name)
      AssociationLoader.for(self.class, association_name).load(self)
    end
    
    def self.switch!(tenant)
      connection.clear_query_cache
      Thread.current[:tenant] = tenant

      ActiveRecord::Base.connection.exec_query(SET_TENANT_ID_SQL % connection.quote(tenant.id), "SQL")
    end
    
    def self.reset!
      connection.clear_query_cache
      Thread.current[:tenant] = nil
      ActiveRecord::Base.connection.exec_query(RESET_TENANT_ID_SQL, "SQL")
    end
    
    def self.switch_tenant_legacy!(oauth_consumer_key = nil)
      if oauth_consumer_key
        tenant_id = ApplicationInstance.find_by(lti_key: oauth_consumer_key)&.tenant_id
        
        if (!tenant_id)
          raise AtomicTenant::Exceptions::InvalidTenantKeyError, oauth_consumer_key
        end

        tenant = Tenant.find(tenant_id)

        switch!(tenant)
      else
        reset!
      end
    end
    
    def self.current_tenant_key
      Thread.current[:tenant]&.key || "public"
    end
    
    def self.current
      Thread.current[:tenant]
    end
    
    def self.switch_tenant_legacy(tenant_key, &block)
      tenant = Tenant.find_by(key: tenant_key)
      switch(tenant, &block)
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
