# frozen_string_literal: true

require 'date'

class Filing < ApplicationRecord
  scope :filed_on_date, ->(date) { where(filed_at: date.all_day) }

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
    Forms.from_filings([self]).first.form_name
  end
end
