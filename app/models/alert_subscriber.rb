# frozen_string_literal: true

class AlertSubscriber < ApplicationRecord
  scope :active, (lambda do
    subscribed.where([<<~SQL, 30.days.ago, 30.days.ago])
      id IN (SELECT DISTINCT(alert_subscriber_id) FROM sent_messages WHERE opened_at > ?)
      OR created_at > ?
    SQL
  end)
  scope :inactive, (lambda do
    subscribed.where([<<~SQL, 30.days.ago, 30.days.ago])
      id NOT IN (SELECT DISTINCT(alert_subscriber_id) FROM sent_messages WHERE opened_at > ?)
      AND created_at < ?
    SQL
  end)
  scope :subscribed, -> { where(unsubscribed_at: nil).where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }
  scope :daily, -> { active.where(subscription_frequency: 'daily') }
  scope :weekly, -> { active.where(subscription_frequency: 'weekly') }

  belongs_to :netfile_agency
  has_many :sent_messages

  enum :subscription_frequency, { daily: 0, weekly: 1 }

  validates :email, format: /\A[^@]+@[^\.]+\.[\w]+\z/i

  before_save :set_token_if_missing

  def self.subscription_frequencies_humanized
    subscription_frequencies.map do |label, value|
      humanized_label = I18n.t("activerecord.alert_subscriber.subscription_frequency.#{label}")

      [humanized_label, label]
    end
  end

  def set_token_if_missing
    return if token.present?

    self[:token] = SecureRandom.hex
  end

  def open_rate
    recent_messages = sent_messages.last(30).to_a
    return 0 if recent_messages.none?

    recent_messages.count { |m| m.opened_at.present? }.to_f /
      recent_messages.count
  end

  def click_rate
    recent_messages = sent_messages.last(30).to_a
    return 0 if recent_messages.none?

    recent_messages.count { |m| m.clicked_at.present? }.to_f /
      recent_messages.count
  end

  def last_opened_at
    sent_messages.opened.last&.opened_at
  end

  def unsubscribe!
    update_attribute(:unsubscribed_at, Time.now)
  end

  def confirm!
    touch(:confirmed_at)
  end
end
