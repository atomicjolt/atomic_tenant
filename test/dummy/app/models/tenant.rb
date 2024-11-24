class Tenant < ApplicationRecord
  set_public_tenanted

  include AtomicTenant::TenantSwitching
end
