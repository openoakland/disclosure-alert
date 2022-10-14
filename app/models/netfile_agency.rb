class NetfileAgency < ApplicationRecord
  def self.create_supported_agencies
    find_or_create_by(netfile_id: 13, shortcut: 'COAK', name: 'Oakland, City of')
    find_or_create_by(netfile_id: 52, shortcut: 'SFO', name: 'San Francisco Ethics Commission')
  end

  def self.coak
    @_coak ||= find_by(shortcut: 'COAK')
  end

  def self.sfo
    @_sfo ||= find_by(shortcut: 'SFO')
  end

  def self.each_supported_agency(&block)
    block.call(coak)
    block.call(sfo)
  end

  def self.by_netfile_id(id)
    @_by_id ||= all.index_by(&:netfile_id)
    @_by_id.fetch(id)
  end
end