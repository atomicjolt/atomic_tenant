require 'rails_helper'

RSpec.describe AtomicTenant::Tenantable, type: :module do
  describe 'class methods' do
    it 'registers a public tenanted model' do
      expect(AtomicTenant::Tenantable.public_tenanted_models).to include(Tenant)
      expect(AtomicTenant::Tenantable.private_tenanted_models).not_to include(Tenant)
    end

    it 'registers a private tenanted model' do
      expect(AtomicTenant::Tenantable.private_tenanted_models).to include(GoodRowSecurityExample)
      expect(AtomicTenant::Tenantable.public_tenanted_models).not_to include(GoodRowSecurityExample)
    end
  end

  describe 'instance methods' do
    let(:tenant) { Tenant.create!(key: 'test') }

    it 'sets tenant id before create' do
      Tenant.switch(tenant) do
        record = GoodRowSecurityExample.new(name: 'test')
        record.save(validate: false)
        expect(record.tenant_id).to eq(tenant.id)
      end
    end

    it 'validates tenant id on updates' do
      Tenant.switch(tenant) do
        record = GoodRowSecurityExample.new(name: 'test')
        record.save!
        record.update(tenant_id: tenant.id + 1)
        expect(record.errors).to include(:tenant_id)
        expect(record.errors[:tenant_id]).to include("must be set to the current tenant's id")
      end
    end

    it 'raises error if tenant is not set' do
      record = GoodRowSecurityExample.new(name: 'test', tenant_id: tenant.id + 1)
      expect { record.save }.to raise_error(AtomicTenant::Exceptions::TenantNotSet)
    end
  end

  describe 'verify_tenanted' do
    it 'raises error if model is not tenanted' do
      Rails.application.eager_load!
      private_models = AtomicTenant::Tenantable.private_tenanted_models.map(&:table_name)

      expect(private_models).not_to be_empty
      expect(private_models).to include('good_row_security_examples')
      expect(private_models).to include('bad_row_security_examples')

      expect do
        AtomicTenant::Tenantable.verify_tenanted(GoodRowSecurityExample)
      end.not_to raise_error

      expect do
        AtomicTenant::Tenantable.verify_tenanted(BadRowSecurityExample)
      end.to raise_error('Model BadRowSecurityExample is not public but does not have row level security. Did you forget to add row level security in your migration?')
    end
  end
end
