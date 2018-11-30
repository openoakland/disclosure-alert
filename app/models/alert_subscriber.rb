# frozen_string_literal: true

class AlertSubscriber < ApplicationRecord
  validates :email, format: /\A[^@]+@[^\.]+\.[\w]+\z/i

  before_save :set_token_if_missing

  def set_token_if_missing
    return if token.present?

    self[:token] = SecureRandom.hex
  end
end
