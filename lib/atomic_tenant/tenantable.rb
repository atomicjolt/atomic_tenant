module AtomicTenant::Tenantable
  extend ActiveSupport::Concern

  @public_tenanted_models = Set.new
  @private_tenanted_models = Set.new

  class << self
    attr_reader :public_tenanted_models, :private_tenanted_models

    def register_public_tenanted_model(model)
      @public_tenanted_models.add(model)
      @private_tenanted_models.delete(model)
    end

    def register_private_tenanted_model(model)
      @private_tenanted_models.add(model)
      @public_tenanted_models.delete(model)
    end

    def verify_tenanted(model)
      query = <<~SQL
        SELECT relrowsecurity
        FROM pg_class
        WHERE relname = $1;
      SQL

      result = ActiveRecord::Base.connection.exec_query(
        query,
        "SQL",
        [
          ActiveRecord::Relation::QueryAttribute.new(
            "relname",
            model.table_name,
            ActiveRecord::Type::String.new
          )
        ],
      )

      if !result.first['relrowsecurity']
        raise "Model #{model.name} is not public but does not have row level security. Did you forget to add row level security in your migration?"
      end
    end
  end

  included do
    class_attribute :is_tenanted, instance_writer: false, default: true

    before_create :set_tenant_id
    before_validation :set_tenant_id, on: :create
    validate :in_current_tenant

    def self.inherited(subclass)
      super

      if subclass <= ActiveRecord::Base && !subclass.abstract_class?
        AtomicTenant::Tenantable.register_private_tenanted_model(subclass)
      end
    end


    private

    def set_tenant_id
      if self.class.is_tenanted?
        tenant = AtomicTenant.tenant_model.current
        raise AtomicTenant::Exceptions::TenantNotSet unless tenant.present?

        self[AtomicTenant.tenanted_by] = tenant.id
      end
    end

    def in_current_tenant
      if self.class.is_tenanted?
        tenant = AtomicTenant.tenant_model.current
        raise AtomicTenant::Exceptions::TenantNotSet unless tenant.present?

        if self[AtomicTenant.tenanted_by] != tenant.id
          errors.add(AtomicTenant.tenanted_by, "must be set to the current tenant's id")
        end
      end
    end
  end

  class_methods do
    def set_public_tenanted
      AtomicTenant::Tenantable.register_public_tenanted_model(self)
      self.is_tenanted = false
    end
  end
end
