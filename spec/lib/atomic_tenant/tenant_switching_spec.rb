require 'rails_helper'

RSpec.describe AtomicTenant::TenantSwitching do
  let(:tenant) { Tenant.create!(key: 'test') }
  let(:tenant_key) { tenant.key }

  describe '.switch!' do
    it 'sets the current tenant' do
      Tenant.switch!(tenant)
      expect(Tenant.current).to eq(tenant)
    end

    it 'resets the tenant when nil is passed' do
      Tenant.switch!(nil)
      expect(Tenant.current).to be_nil
    end
  end

  describe '.reset!' do
    it 'resets the current tenant' do
      Tenant.switch!(tenant)
      Tenant.reset!
      expect(Tenant.current).to be_nil
    end
  end

  describe '.switch_tenant_legacy!' do
    context 'with a valid tenant key' do
      it 'sets the current tenant' do
        Tenant.switch_tenant_legacy!(tenant_key)
        expect(Tenant.current).to eq(tenant)
      end
    end

    context 'with an invalid tenant key' do
      it 'raises an error' do
        expect do
          Tenant.switch_tenant_legacy!('invalid_key')
        end.to raise_error(AtomicTenant::Exceptions::InvalidTenantKeyError)
      end
    end
  end

  describe '.current_key' do
    it 'returns the current tenant key' do
      Tenant.switch!(tenant)
      expect(Tenant.current_key).to eq(tenant_key)
    end

    it 'returns "public" when no tenant is set' do
      Tenant.reset!
      expect(Tenant.current_key).to eq('public')
    end
  end

  describe '.switch' do
    it 'switches to the tenant for the duration of the block' do
      block_tenant = nil
      Tenant.switch(tenant) do
        block_tenant = Tenant.current
      end

      expect(block_tenant).to eq(tenant)
      expect(Tenant.current).to be_nil
    end

    it 'resets to the previous tenant after the block' do
      previous_tenant = Tenant.create!(key: 'previous')
      Tenant.switch!(previous_tenant)

      block_tenant = nil
      Tenant.switch(tenant) do
        block_tenant = Tenant.current
      end

      expect(block_tenant).to eq(tenant)
      expect(Tenant.current).to eq(previous_tenant)
    end
  end

  describe '.switch_tenant_legacy' do
    it 'switches to the tenant for the duration of the block' do
      block_tenant = nil
      Tenant.switch_tenant_legacy(tenant_key) do
        block_tenant = Tenant.current
      end

      expect(block_tenant).to eq(tenant)
      expect(Tenant.current).to be_nil
    end

    it 'resets to the previous tenant after the block' do
      previous_tenant = Tenant.create!(key: 'previous')
      Tenant.switch!(previous_tenant)

      block_tenant = nil
      Tenant.switch_tenant_legacy(tenant_key) do
        block_tenant = Tenant.current
      end

      expect(block_tenant).to eq(tenant)
      expect(Tenant.current).to eq(previous_tenant)
    end

    it 'raises an error with an invalid tenant key' do
      expect do
        Tenant.switch_tenant_legacy('invalid_key') {}
      end.to raise_error(AtomicTenant::Exceptions::InvalidTenantKeyError)
    end
  end

  describe '.tenant_from_key!' do
    context 'with a valid tenant key' do
      it 'returns the tenant' do
        result = Tenant.tenant_from_key!(tenant_key)
        expect(result).to eq(tenant)
      end
    end

    context 'with an invalid tenant key' do
      it 'raises an error' do
        expect do
          Tenant.tenant_from_key!('invalid_key')
        end.to raise_error(AtomicTenant::Exceptions::InvalidTenantKeyError)
      end
    end
  end
end
