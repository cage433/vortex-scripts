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


  def self.ids_for_month(year, month_no)
    AlexEvents.all(
      fields: [ALEX_ID],
      filter: filter_text(
        Date.new(year, month_no, 1),
        Date.new(year, month_no, -1)
      )
    )
  end

  def self.records_for_date_range(first_date, last_date)
    AlexEvents.all(
      fields: [ALEX_EVENT_DATE, ALEX_EVENT_TITLE, ALEX_GIGS],
      filter: filter_text(first_date, last_date)
    )
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


class AlexGigs < ExtendedTable
  self.base_key = ALEX_VORTEX_DB_ID
  self.table_name = ALEX_GIG_TABLE

  def self.record_for_id(id)
    AlexGigs.find(id)
  end

  def self.update_vol_data(event)
    event_date_formatted = event.event_date.strftime("%Y-%m-%d")
    #filter_text = "AND({#{ALEX_EVENT_DATE}} >= '#{event_date_formatted}',{#{ALEX_EVENT_DATE}} <= '#{event_date_formatted}')"
    filter_text = "{#{ALEX_EVENT_DATE}} >= '#{event_date_formatted}'"
    gig_records = AlexGigs.all(
      fields: [ALEX_GIG_TIME, ALEX_EVENT_DATE, ALEX_VOL_1, ALEX_VOL_2],
      filter: filter_text

    )
    #gig1_record = AlexGigs.find(EventMediator.gig1_airtable_id(event))
    puts("here #{event_date_formatted}")
    #puts(gig_records.size)
    gig_records.each do |rec|
      rec_date = rec[ALEX_EVENT_DATE]
      #puts(rec_date)
      #puts(rec_date.class)
      #puts(rec_date.size)
      is_same = rec_date == event_date_formatted
      vol_1 = rec[ALEX_VOL_1]
      puts(vol_1.class)
      puts(vol_1)
      puts(is_same)
    end

  end
end
