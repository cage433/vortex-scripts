require_relative '../env'
require_relative 'original_contracts_table'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module EventTableMeta
  TABLE = "Event"

  ID = "id"
  TITLE = "Title"
  DATE = "Date"
  GIG_IDS = "Gig Ids"
  SOUND_ENGINEER = "Sound Engineer"
  FEE_NOTES = "Fee Notes"
  FLAT_FEE = "Flat Fee"
  MIN_FEE = "Min Fee"
  FEE_PERCENTAGE = "Fee %age"
end

class EventTable < Airrecord::Table

  include EventTableMeta
   
  self.base_key = ALEX_VORTEX_DB_ID
  self.table_name = TABLE

  def self.filter_text(first_date, last_date)
    first_date_formatted = first_date.strftime("%Y-%m-%d")
    last_date_formatted = last_date.strftime("%Y-%m-%d")
    "AND({#{DATE}} >= '#{first_date_formatted}',{#{DATE}} <= '#{last_date_formatted}')"
  end

  def self.populate_for_date_range(first_date, last_date)
    original_contracts = OriginalContractsTable.all_records().filter do |c| 
      performance_date = Date.parse(c[OriginalContractsTableMeta::PERFORMANCE_DATES])
      performance_date >= first_date && performance_date <= last_date
    end
    original_contracts.each do |c|
      EventTable.create(
        {
          DATE => Date.parse(c[OriginalContractsTableMeta::PERFORMANCE_DATES]),
          TITLE => c[OriginalContractsTableMeta::EVENT_TITLE],
          EVENT_TYPE => "Standard Evening Gig",
        }
      )
    end
  end

  def self.ids_for_date_range(first_date, last_date)
    recs = EventTable.all(
      fields: [ID],
      filter: filter_text(first_date, last_date)
    )
    recs.collect { |rec| rec[ID] }
  end


  def self.ids_for_month(year, month_no)
    self.ids_for_date_range(
      Date.new(year, month_no, 1),
      Date.new(year, month_no, -1)
    )
  end


end


