# Use in case of emergency.
#
# Usage:
#   send = ManualSend.new(
#     date_from: Date.new(2020, 9, 12),
#     date_to: Date.new(2020, 9, 23),
#     notice: "From 9/12 we had a filing error."
#   )
#   send.preview
#   send.execute!
#
class ManualSend
  def initialize(date_from:, date_to:, notice: nil, tom_only: false)
    @range = date_from..date_to
    @notice_text = notice
    @tom_only = tom_only
  end

  def preview
    puts "Will send to #{subscribers.count} subscribers:"
    subscribers.each do |subscriber|
      puts "  * #{subscriber.email}"
    end

    puts
    puts "Will send #{filings.count} filings."
    filings.each do |filing|
      puts "  * #{filing.filed_at.to_date} - #{filing.title}"
    end

    puts
    puts "Sending with notice: #{@notice.body}" if @notice_text
  end

  def execute!
    subscribers.each do |subscriber|
      AlertMailer
        .daily_alert(subscriber, @range, filings, @notice)
        .deliver_now
    end
  end

  private

  def subscribers
    @subscribers ||= if @tom_only
                       [AlertSubscriber.find_by(email: 'tomdooner@gmail.com')]
                     else
                       AlertSubscriber.subscribed.to_a
                     end
  end

  def filings
    @filings ||= Filing.filed_in_date_range(@range).order(filed_at: :asc).to_a
  end

  def notice
    return nil unless @notice_text.present?

    @notice ||= Notice.new(
      date: @range.max,
      creator: AdminUser.find_by(email: 'tomdooner@gmail.com'),
      body: @notice_text,
    )
  end
end
