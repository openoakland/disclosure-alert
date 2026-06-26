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

  desc 'Send a test alert email to a specific address, e.g. rake disclosure_alert:send_test_email[you@example.com]'
  task :send_test_email, [:email] => :with_configuration do |_t, args|
    email = args[:email] || ENV['EMAIL']
    raise 'Provide an email: rake disclosure_alert:send_test_email[you@example.com]' if email.blank?

    today = TZInfo::Timezone.get('America/Los_Angeles').now.to_date
    days_ago = 0

    filings = loop do
      found = Filing.filed_on_date(today - days_ago)
      break found if found.any?
      days_ago += 1
      raise 'No filings found in the database' if days_ago > 30
    end

    subscriber = AlertSubscriber.where(email: email).first_or_create!
    puts "Sending test alert to #{email} with #{filings.count} filings from #{today - days_ago}..."
    AlertMailer.daily_alert(subscriber, today - days_ago, filings).deliver_now
    puts 'Done.'
  end

  desc 'Download filings for a specific date range, e.g. rake disclosure_alert:download_range[2026-01-01,2026-01-31]'
  task :download_range, [:start_date, :end_date] => :with_configuration do |_t, args|
    start_date = Date.parse(args[:start_date])
    end_date   = Date.parse(args[:end_date])
    DisclosureDownloader.new.download_range(start_date, end_date)
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
