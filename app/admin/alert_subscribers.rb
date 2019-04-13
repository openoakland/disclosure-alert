ActiveAdmin.register AlertSubscriber do
  index do
    selectable_column
    id_column
    column :email
    column :subscribed_at, :created_at
    column :open_rate
    column :click_rate
    actions
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
end
