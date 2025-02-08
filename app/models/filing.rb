# frozen_string_literal: true

require 'date'

class Filing < ApplicationRecord
  scope :filed_on_date, ->(date) { where(filed_at: date.all_day) }
  scope :filed_in_date_range, ->(range) { where(filed_at: range) }
  scope :for_email, -> { includes(:amended_filing, :election_candidates, :election_committee) }

  # Find spreadsheet entries related to these entities
  has_many :election_candidates, foreign_key: :fppc_id, primary_key: :filer_id
  has_one :election_committee, foreign_key: :fppc_id, primary_key: :filer_id
  has_one :amended_filing, class_name: 'Filing', primary_key: :amended_filing_id, foreign_key: :id
  has_one :election_referendum, through: :election_committee
  belongs_to :netfile_agency

  def self.from_json(json)
    find_or_initialize_by(id: json['id']) do |record|
      record.filer_id = json['filerStateId']
      record.filer_name = json['filerName']
      record.title = json['title']
      record.netfile_agency = NetfileAgency.by_netfile_id(json['agency'])
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
