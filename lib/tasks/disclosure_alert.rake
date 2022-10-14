namespace :disclosure_alert do
  task with_configuration: :environment do
    if ENV['MAILGUN_API_KEY'].empty?
      warn '======================================================'
      warn 'Warning: No configuration value for MAILGUN_API_KEY.'
      warn ''
      warn 'Emails will not be sent. See the README for instructions'
      warn 'on setting that value.'
      warn '======================================================'
      sleep 3
    end
  end

  desc 'Download latest records'
  task download: :environment do
    NetfileAgency.each_supported_agency do |agency|
      DisclosureDownloader.new(agency).download
    end
  end

  desc 'Download latest records and send email'
  task download_and_email_daily: :with_configuration do
    today = TZInfo::Timezone.get('America/Los_Angeles').now.to_date
    NetfileAgency.each_supported_agency do |agency|
      DisclosureDownloader.new(agency).download
    end
    DisclosureEmailer.new(today - 1).send_email
  end

  desc 'Resends the last email to Tom for testing purposes'
  task resend_last_to_tom: :with_configuration do
    today = TZInfo::Timezone.get('America/Los_Angeles').now.to_date
    days_ago = 1
    tom = AlertSubscriber.find_by(email: 'tomdooner@gmail.com')
    filings = []

    loop do
      filings = Filing.filed_on_date(today - days_ago).for_email
      break if filings.any?
      days_ago += 1
    end

    AlertMailer
      .daily_alert(tom, today - days_ago, filings)
      .deliver_now
  end

  desc 'Add subscriber to the daily email'
  task add_daily_subscriber: :with_configuration do
    puts 'Add subscriber to daily email?'
    $stdout.write 'Email Address: '
    email = $stdin.gets.chomp

    return unless DisclosureAlert::AlertSubscriber.create(email: email)
    puts 'Subscribed!'
  end

  desc 'Backfill missing filing contents from already-downloaded filings'
  task backfill: :with_configuration do
    DisclosureDownloader.new.backfill_contents
  end
end
