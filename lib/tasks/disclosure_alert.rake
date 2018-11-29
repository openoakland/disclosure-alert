namespace :disclosure_alert do
  desc 'Download latest records and send email'
  task download_and_email_daily: :environment do
    today = TZInfo::Timezone.get('America/Los_Angeles').now.to_date
    DisclosureDownloader.new.download
    DisclosureEmailer.new(today - 1).send_email
  end

  desc 'Add subscriber to the daily email'
  task add_daily_subscriber: :environment do
    puts 'Add subscriber to daily email?'
    $stdout.write 'Email Address: '
    email = $stdin.gets.chomp

    if DisclosureAlert::AlertSubscriber.create(email: email)
      puts 'Subscribed!'
    end
  end
end
