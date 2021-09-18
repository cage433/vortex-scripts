require_relative '../env'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module OriginalContractsTableMeta
  CONTRACTS_TABLE = "Contracts"
  EVENT_TITLE = "Event title"
  PERFORMANCE_DATES = "Performance dates"
end

class OriginalContractsTable < Airrecord::Table

  include OriginalContractsTableMeta

  self.base_key = VORTEX_DATABASE_ID
  self.table_name = CONTRACTS_TABLE

  def self.all_records()
    self.all(fields:[EVENT_TITLE, PERFORMANCE_DATES]).filter { |r|
      begin
        Date.parse(r[PERFORMANCE_DATES])
        true
      rescue
        false
      end
    }
  end

end

