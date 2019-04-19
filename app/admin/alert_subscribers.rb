ActiveAdmin.register AlertSubscriber do
  permit_params :unsubscribed_at, :email

  scope :all
  scope :active, default: true
  scope :unsubscribed

  index do
    selectable_column
    id_column
    column :email
    column :subscribed_at, :created_at
    column :unsubscribed_at
    column(:open_rate) { |as| format('%.1f%%', as.open_rate * 100) }
    column(:click_rate) { |as| format('%.1f%%', as.click_rate * 100) }
    column(:total_emails) { |as| as.ahoy_messages.count }
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :email
      f.input :unsubscribed_at, as: :datetime_picker
    end
    f.actions
  end

  action_item :send_yesterdays_email, only: :show do
    link_to 'Send Yesterdays Email',
      send_yesterdays_email_admin_alert_subscriber_path(resource),
      method: :put
  end

  member_action :send_yesterdays_email, method: :put do
    yesterday = Date.yesterday

    AlertMailer
      .daily_alert(resource, yesterday, Filing.filed_on_date(yesterday))
      .deliver_now

    redirect_to resource_path, notice: 'Email Sent!'
  end

  batch_action :unsubscribe do |ids|
    AlertSubscriber.where(id: ids).find_each(&:unsubscribe!)
  end
end
