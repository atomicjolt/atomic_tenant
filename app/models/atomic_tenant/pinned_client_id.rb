module AtomicTenant
  class PinnedClientId < ApplicationRecord
    belongs_to :application_instance
  end
end
