$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'disclosure_alert'

ActiveRecord::Base.configurations = {
  (ENV['APP_ENV'] || 'development') => { 'url' => ENV['DATABASE_URL'] }
}

desc 'Download latest records and send email'
task :download_and_email_daily do
  today = TZInfo::Timezone.get('America/Los_Angeles').now.to_date
  DisclosureAlert::Downloader.new.download
  DisclosureAlert::Emailer.new(today - 1).send_email
end

namespace :db do
  task :environment do
    include ActiveRecord::Tasks
    DatabaseTasks.env = ENV['APP_ENV'] || 'development'
    DatabaseTasks.db_dir = 'db'
  end

  desc 'Reset'
  task reset: :environment do
    DatabaseTasks.drop_current
    DatabaseTasks.create_current
    DatabaseTasks.migrate
  end

  desc 'Migrate Database'
  task migrate: :environment do
    DatabaseTasks.migrate
  end
end
