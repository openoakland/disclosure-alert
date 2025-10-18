class SentMessage < ApplicationRecord
  belongs_to :alert_subscriber, counter_cache: true

  scope :opened, -> { where.not(opened_at: nil) }
  scope :bounced, -> { where.not(bounced_at: nil) }
end
