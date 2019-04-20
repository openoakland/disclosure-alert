# frozen_string_literal: true

require 'date'

class Filing < ApplicationRecord
  FORM_IDS = {
    30 => '460',
    236 => 'LOB',         # LOB = Oakland Lobbyist Quarterly Report
    39 => '497 LCR',      # LCR = Late Contributions Received
    38 => '497 LCM',      # LCM = Late Contributions Made
    254 => '700',
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
    FORM_IDS[form.to_i]
  end
end
