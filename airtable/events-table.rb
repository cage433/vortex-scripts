require_relative '../env'
require_relative './fields'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

class ExtendedTable < Airrecord::Table
  def self.fields()
    raise "Implement the fields method"
  end
  def self.all_records(filter_text = nil)
    self.all(
      fields: self.fields,
      filter: filter_text
    )
  end
end

class OriginalContracts < ExtendedTable
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = ORIGINAL_CONTRACTS_TABLE

  def self.fields()
    [ORIGINAL_EVENT_TITLE, ORIGINAL_PERFORMANCE_DATES]
  end

  def self.all_records(filter_text = nil)
    super.filter do |r|
      begin
        Date.parse(r[ORIGINAL_PERFORMANCE_DATES])
        true
      rescue
        false
      end
    end
  end

end


class AlexEvents < ExtendedTable
   
  self.base_key = ALEX_VORTEX_DB_ID
  self.table_name = ALEX_EVENTS_TABLE

  def self.filter_text(first_date, last_date)
    first_date_formatted = first_date.strftime("%Y-%m-%d")
    last_date_formatted = last_date.strftime("%Y-%m-%d")
    "AND({#{ALEX_EVENT_DATE}} >= '#{first_date_formatted}',{#{ALEX_EVENT_DATE}} <= '#{last_date_formatted}')"
  end

  def self.populate_for_date_range(first_date, last_date)
    original_contracts = OriginalContracts.all_records().filter do |c| 
      performance_date = Date.parse(c[ORIGINAL_PERFORMANCE_DATES])
      performance_date >= first_date && performance_date <= last_date
    end
    original_contracts.each do |c|
      AlexEvents.create(
        {
          ALEX_EVENT_DATE => Date.parse(c[ORIGINAL_PERFORMANCE_DATES]),
          ALEX_EVENT_TITLE => c[ORIGINAL_EVENT_TITLE],
          ALEX_EVENT_TYPE => ALEX_STANDARD_EVENING_GIG,
        }
      )
    end

  end

  def self.records_for_date_range(first_date, last_date)
    AlexEvents.all(
      fields: [ALEX_EVENT_DATE, ALEX_EVENT_TITLE],
      filter: filter_text(first_date, last_date)
    )
    #end
  end

  def self.records_for_month(year, month_no)
    self.records_for_date_range(
      Date.new(year, month_no, 1),
      Date.new(year, month_no, -1)
    )
  end

  def self.has_record_for_date?(date)
    !self.record_for_date(date).nil?
  end

end


