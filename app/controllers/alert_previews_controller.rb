class AlertPreviewsController < ApplicationController
  def show
    @email_date = case params[:date]
                  when "today"
                    Time.zone.today
                  when "yesterday"
                    Time.zone.yesterday
                  end

    @forms = Forms.from_filings(
      Filing
        .filed_on_date(@email_date - 1)
        .where(netfile_agency: NetfileAgency.coak)
        .for_email
    )
    @upcoming_deadlines = FilingDeadline.future.but_not_too_future
      .relevant_to_agency(NetfileAgency.coak)
  end
end
