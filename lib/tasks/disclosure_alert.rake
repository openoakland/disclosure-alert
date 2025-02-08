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

  desc 'Add subscriber to the daily email'
  task add_daily_subscriber: :with_configuration do
    puts 'Add subscriber to daily email?'
    $stdout.write 'Email Address: '
    email = $stdin.gets.chomp

    return unless DisclosureAlert::AlertSubscriber.create(email: email)
    puts 'Subscribed!'
  end

  desc 'Backfill missing filing contents from already-downloaded filings'
  task backfill_contents: :with_configuration do
    NetfileAgency.each_supported_agency do |agency|
      DisclosureDownloader.new(agency).backfill_contents
    end
  end

  # Invoke like:
  #   bin/rails 'disclosure_alert:backfill_filings[since="2024-01-01"]'
  desc 'Backfill missing filing contents from already-downloaded filings'
  task :backfill_filings, [:since] => :with_configuration do |_t, args|
    since = Date.parse(args[:since])
    NetfileAgency.each_supported_agency do |agency|
      DisclosureDownloader.new(agency).backfill_filings(since)
    end
  end
end
