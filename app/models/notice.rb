# frozen_string_literal: true

class Notice < ApplicationRecord
  # A Notice is an alert sent to all users at the top of the next email they
  # will receive.
  belongs_to :creator, class_name: 'AdminUser'

  validates :date, uniqueness: true

  scope :for_date, ->(date) { find_by(date: date) }

  before_save :sanitize
  def sanitize
    self.body = ActionController::Base.helpers.sanitize(body)
  end
end
