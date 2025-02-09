class FilingDeadline < ApplicationRecord
  # See (e.g.):
  #   https://www.fppc.ca.gov/content/dam/fppc/NS-Documents/TAD/Filing%20Schedules/2024/november-2024/state/2024_01_State_Nov_5_Cand_Final.pdf
  enum :deadline_type, [:semi_annual, :late_contribution_window, :pre_election]

  scope :future, -> { where('date > ?', Date.today) }
  scope :but_not_too_future, -> { where('date < ?', 90.days.from_now) }
  scope :relevant_to_agency, ->(agency) do
    future.where(netfile_agency_id: nil).or(
      future.where(netfile_agency_id: agency.netfile_id)
    )
  end
end
