require 'mailgun-ruby'
require 'haml'
require 'premailer'

class DisclosureEmailer
  def initialize(send_date)
    @send_date = send_date
  end

  def send_email
    NetfileAgency.each_supported_agency do |agency|
      subscribers = AlertSubscriber.subscribed.where(netfile_agency: agency)

      puts '==================================================================='
      puts "Emailing to #{subscribers.count} subscribers of #{agency.shortcut}:"
      puts '==================================================================='

      subscribers.find_each do |subscriber|
        begin
          AlertMailer
            .daily_alert(subscriber, @send_date)
            .deliver_now
        rescue AlertMailer::NoFilingsToSend => ex
          puts "Failed to send: #{ex.message}"
        end
      end
    end
  end
end
