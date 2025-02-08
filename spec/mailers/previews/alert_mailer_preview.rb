# frozen_string_literal: true

class AlertMailerPreview < ActionMailer::Preview
  def daily_alert
    AlertMailer.daily_alert(
      find_or_create_subscriber,
      Date.yesterday,
      filings,
      notice('A notice to the user would appear here.'),
    )
  end

  private

  def find_or_create_subscriber
    AlertSubscriber
      .where(email: 'test+preview@example.com')
      .first_or_create
  end

  def filings
    Filing
      .includes(:election_committee, :election_candidates, :election_referendum, :amended_filing)
      .order(filed_at: :desc)
      .first(30)
  end

  def notice(text)
    Notice.new(
      creator: AdminUser.first,
      date: Date.yesterday,
      body: text,
      informational: Random.rand < 0.5
    )
  end
end
