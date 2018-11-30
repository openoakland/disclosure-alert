# frozen_string_literal: true

class AlertSubscriber < ApplicationRecord
  validates :email, format: /\A[^@]+@[^\.]+\.[\w]+\z/i
end
