# frozen_string_literal: true

class AlertSubscriber < ApplicationRecord
  scope :active, (lambda do
    subscribed.where([<<~SQL, 30.days.ago, 30.days.ago])
      id IN (SELECT DISTINCT(user_id) FROM ahoy_messages WHERE opened_at > ?)
      OR created_at > ?
    SQL
  end)
  scope :inactive, (lambda do
    subscribed.where([<<~SQL, 30.days.ago, 30.days.ago])
      id NOT IN (SELECT DISTINCT(user_id) FROM ahoy_messages WHERE opened_at > ?)
      AND created_at < ?
    SQL
  end)
  scope :subscribed, -> { where(unsubscribed_at: nil).where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }

  has_many :ahoy_messages, foreign_key: :user_id
  belongs_to :netfile_agency
  has_many :sent_messages

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

  def last_opened_at
    ahoy_messages.opened.last&.opened_at
  end

  def unsubscribe!
    update_attribute(:unsubscribed_at, Time.now)
  end

  def confirm!
    touch(:confirmed_at)
  end
end
