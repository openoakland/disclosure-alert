# frozen_string_literal: true

class AlertSubscriber < ApplicationRecord
  has_many :ahoy_messages, foreign_key: :user_id

  validates :email, format: /\A[^@]+@[^\.]+\.[\w]+\z/i

  before_save :set_token_if_missing

  def set_token_if_missing
    return if token.present?

    self[:token] = SecureRandom.hex
  end

  def open_rate
    ahoy_messages.where('opened_at is not null').last(30).count.to_f /
      ahoy_messages.last(30).count
  end

  def click_rate
    ahoy_messages.where('clicked_at is not null').last(30).count.to_f /
      ahoy_messages.last(30).count
  end
end
