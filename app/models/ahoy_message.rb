class AhoyMessage < ApplicationRecord
  scope :opened, -> { where.not(opened_at: nil) }
end
