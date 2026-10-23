class NetfileAgency < ApplicationRecord
  # San Francisco (SFO, netfile_id 52) was dropped. Its NetfileAgency row is
  # left in the database on purpose: existing Filing, FilingDeadline and
  # AlertSubscriber rows still reference it, and AlertSubscriber requires a
  # netfile_agency. Nothing fetches or emails it now that it is not yielded
  # below.
  def self.create_supported_agencies
    find_or_create_by(netfile_id: 13, shortcut: 'COAK', name: 'Oakland, City of')
  end

  def self.coak
    @_coak ||= find_by(shortcut: 'COAK')
  end

  def self.each_supported_agency
    return to_enum(:each_supported_agency) unless block_given?

    yield coak
  end

  def self.by_netfile_id(id)
    @_by_id ||= all.index_by(&:netfile_id)
    @_by_id.fetch(id)
  end
end
