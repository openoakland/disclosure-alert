# frozen_string_literal: true

require 'date'

class Filing < ApplicationRecord
  FORM_IDS = {
    '460' => 30,
    'LOB' => 36,          # LOB = Oakland Lobbyist Quarterly Report
    'LOB' => 236,         # LOB = Oakland Lobbyist Quarterly Report
    '497 LCR' => 39,      # LCR = Late Contributions Received
    '497 LCM' => 38       # LCM = Late Contributions Made
  }.freeze

  scope :filed_on_date, ->(date) { where("date_trunc('day', filed_at) = ?", date) }

  def self.from_json(json)
    find_or_initialize_by(id: json['id']) do |record|
      record.filer_id = json['filerStateId']
      record.filer_name = json['filerName']
      record.title = json['title']
      record.filed_at = DateTime.parse(json['filingDate'])
      record.amendment_sequence_number = json['amendmentSequenceNumber']
      record.amended_filing_id = json['amendedFilingId']
      record.form = json['form']
    end
  end

  def form_name
    FORM_IDS.invert[form.to_i]
  end
end
