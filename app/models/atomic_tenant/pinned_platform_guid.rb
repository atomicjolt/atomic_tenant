module AtomicTenant
  class PinnedPlatformGuid < ApplicationRecord
    belongs_to :application
    belongs_to :application_instance
  end
end
