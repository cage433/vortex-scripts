require_relative '../env'
require_relative 'original_contracts_table'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module EventTableMeta
  TABLE = "Events"

  ID = "Record ID"
  SHEETS_EVENT_TITLE = "SheetsEventTitle"
  EVENT_DATE = "Event Date"
  DOORS_TIME = "Doors Time"
  SOUND_ENGINEER = "Sound Engineer"
  NIGHT_MANAGER_NAME = "Night Manager Name"
  VOL_1 = "Vol 1 Name"
  VOL_2 = "Vol 2 Name"
  PRIMARY_EVENT_TYPE = "Primary Event Type"
  STATUS = "Status"
  #FEE_NOTES = "Fee Notes"
  #FLAT_FEE = "Flat Fee"
  #MIN_FEE = "Min Fee"
  #FEE_PERCENTAGE = "Fee %age"
end

class EventTable < Airrecord::Table

  include EventTableMeta
   
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  def self.filter_text(first_date, last_date)
    first_date_formatted = first_date.strftime("%Y-%m-%d")
    last_date_formatted = last_date.strftime("%Y-%m-%d")
    "AND({#{EVENT_DATE}} >= '#{first_date_formatted}',{#{EVENT_DATE}} <= '#{last_date_formatted}', {#{STATUS}} = 'Confirmed')"
  end

  #def self.populate_for_date_range(first_date, last_date)
    #original_contracts = OriginalContractsTable.all_records().filter do |c| 
      #performance_date = Date.parse(c[OriginalContractsTableMeta::PERFORMANCE_DATES])
      #performance_date >= first_date && performance_date <= last_date
    #end
    #original_contracts.each do |c|
      #EventTable.create(
        #{
          #DATE => Date.parse(c[OriginalContractsTableMeta::PERFORMANCE_DATES]),
          #TITLE => c[OriginalContractsTableMeta::EVENT_TITLE],
          #EVENT_TYPE => "Standard Evening Gig",
        #}
      #)
    #end
  #end

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


