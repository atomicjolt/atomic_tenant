class ApplicationInstance < ApplicationRecord
  set_public_tenanted

  belongs_to :application
end
