class SentMessage < ApplicationRecord
  belongs_to :alert_subscriber

  scope :opened, -> { where.not(opened_at: nil) }
end
