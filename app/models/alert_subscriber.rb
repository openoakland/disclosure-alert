# frozen_string_literal: true

class AlertSubscriber < ApplicationRecord
  scope :active, -> { where(unsubscribed_at: nil) }
  scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }

  has_many :ahoy_messages, foreign_key: :user_id

  validates :email, format: /\A[^@]+@[^\.]+\.[\w]+\z/i

  before_save :set_token_if_missing

  def set_token_if_missing
    return if token.present?

    self[:token] = SecureRandom.hex
  end

  def open_rate
    recent_messages = ahoy_messages.last(30)
    recent_messages.count { |m| m.opened_at.present? }.to_f /
      recent_messages.count
  end

  def click_rate
    recent_messages = ahoy_messages.last(30)
    recent_messages.count { |m| m.clicked_at.present? }.to_f /
      recent_messages.count
  end

  def unsubscribe!
    update_attribute(:unsubscribed_at, Time.now)
  end
end
