ActiveAdmin.register AlertSubscriber do
  permit_params :unsubscribed_at, :email, :netfile_agency_id, :subscription_frequency

  filter :email
  filter :created_at
  filter :updated_at
  filter :unsubscribed_at
  filter :netfile_agency
  filter :subscription_frequency, as: :select, collection: AlertSubscriber.subscription_frequencies

  scope :all
  scope :active, default: true
  scope :inactive
  scope :unsubscribed
  scope :unconfirmed

  index do
    selectable_column
    id_column
    column :email
    column :subscribed_at, :created_at
    column :unsubscribed_at
    column(:last_opened_at) { |as| as.last_opened_at ? time_ago_in_words(as.last_opened_at) : 'never' }
    column(:open_rate) { |as| format('%.1f%%', as.open_rate * 100) }
    column(:click_rate) { |as| format('%.1f%%', as.click_rate * 100) }
    column(:total_emails) { |as| as.sent_messages.count }
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :email
      f.input :netfile_agency

      frequencies = AlertSubscriber.subscription_frequencies.map do |name, value|
        [name.humanize, name]
      end
      f.input :subscription_frequency, as: :select, collection: frequencies
    end
    f.actions
  end

  csv do
    column :email
    column(:subscribed_at, &:created_at)
    column :unsubscribed_at
    column :last_opened_at
    column :open_rate
    column :click_rate
    column(:total_emails) { |as| as.sent_messages.count }
  end

  action_item :send_yesterdays_email, only: :show do
    link_to 'Send Yesterdays Email',
      send_yesterdays_email_admin_alert_subscriber_path(resource),
      method: :put
  end

  action_item :unsubscribe_or_resubscribe, only: :show do
    if resource.unsubscribed_at?
      link_to(
        'Resubscribe',
        resubscribe_admin_alert_subscriber_path(resource),
        method: :put
      )
    else
      link_to(
        'Unsubscribe',
        unsubscribe_admin_alert_subscriber_path(resource),
        method: :put
      )
    end
  end

  action_item :confirm, only: :show do
    unless resource.confirmed_at?
      link_to(
        'Confirm Subscription',
        confirm_admin_alert_subscriber_path(resource),
        method: :put
      )
    end
  end

  member_action :send_yesterdays_email, method: :put do
    send_date = Date.yesterday

    begin
      AlertMailer
        .daily_alert(resource, send_date)
        .deliver_now
    rescue AlertMailer::NoFilingsToSend => ex
      return redirect_to resource_path, alert: "Failed to send: #{ex.message}"
    end

    redirect_to resource_path, notice: 'Email Sent!'
  end

  member_action :unsubscribe, method: :put do
    resource.unsubscribe!

    redirect_to resource_path, notice: 'Unsubscribed!'
  end

  member_action :resubscribe, method: :put do
    resource.update(unsubscribed_at: nil)

    redirect_to resource_path, notice: 'Resubscribed!'
  end

  member_action :confirm, method: :put do
    resource.confirm!

    redirect_to resource_path, notice: 'Subscription Confirmed!'
  end

  batch_action :unsubscribe do |ids|
    AlertSubscriber.where(id: ids).find_each(&:unsubscribe!)
  end
end
