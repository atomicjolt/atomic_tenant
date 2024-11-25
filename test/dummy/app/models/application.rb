class Application < ApplicationRecord
  set_public_tenanted
  has_many :application_instances
end
