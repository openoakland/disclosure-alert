namespace :admin do
  desc 'Create an Admin User'
  task create_user: :environment do
    require 'io/console'
    puts '============================='
    puts 'Create Admin User:'
    puts '============================='
    puts
    $stdout.write 'Email: '
    email = $stdin.gets.chomp
    $stdout.write 'Password: '
    password = $stdin.noecho(&:gets).chomp
    puts
    if AdminUser.create(email: email, password: password)
      puts 'Created!'
    end
  end

  desc 'Backfill Ahoy::Message -> SentMessage'
  task backfill_sent_messages: :environment do
    SentMessage.transaction do
      Ahoy::Message.find_each do |message|
        SentMessage.create(
          alert_subscriber_id: message.user_id,
          message_id: message.token,
          sent_at: message.sent_at,
          opened_at: message.opened_at,
          clicked_at: message.clicked_at,
          mailer: message.mailer
        )
      end
    end
  end
end
