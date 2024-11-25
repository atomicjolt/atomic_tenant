module AtomicTenant
  module ActiveJob
    extend ActiveSupport::Concern

    class_methods do
      def execute(job_data)
        tenant_key = job_data.delete("tenant")
        tenant = AtomicTenant.tenant_model.find_by(key: tenant_key)
        AtomicTenant.tenant_model.switch(tenant) do
          super
        end
      end
    end

    def initialize(*_args, **_kargs)
      @tenant = AtomicTenant.tenant_model.current_key
      super
    end

    def serialize
      super.merge('tenant' => @tenant)
    end
  end
end
