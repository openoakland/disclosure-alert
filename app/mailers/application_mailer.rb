class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  default 'Message-Id' => proc { Mail::MessageIdField.new.value }

  layout 'mailer'

  after_action :create_sent_message

  private

  def create_sent_message
    SentMessage.create(
      alert_subscriber: AlertSubscriber.find_by(email: message.to.first),
      message_id: message.message_id,
      mailer: "#{mailer_name}/#{action_name}",
      subject: message.subject,
      sent_at: Time.current,
    )
  end
end
