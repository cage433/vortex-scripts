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

class AlexEventRecords
  attr_reader :events
  def initialize(events)
    @events = events
  end

  def sorted()
    @events.sort! { |a, b| a.event_date <=> b.event_date }
  end

  def size
    @events.size
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

class AlexEvent
  attr_reader :event_date, :event_title

  def initialize(record_id, event_date, event_title)
    @event_date = event_date
    @event_title = event_title
  end

  def self.from_record(record)
    record_id = record.id
    event_date = Date.parse(record[ALEX_EVENT_DATE])
    event_title = record[ALEX_EVENT_TITLE]
    AlexEvent.new(record_id, event_date, event_title)
  end

  def to_s()
    "#{@event_title}, #{@event_date}"
  end
end

class AlexEvents < ExtendedTable
   
  self.base_key = ALEX_VORTEX_DB_ID
  self.table_name = ALEX_EVENTS_TABLE

  def self.all_events()
    all_records = AlexEvents.all(
      fields: [ALEX_EVENT_DATE, ALEX_EVENT_TITLE],
    )
    all_records.collect do |record|
      AlexEvent.from_record(record)
    end
  end

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

  def self.events_for_date_range(first_date, last_date)
    all_records = AlexEvents.all(
      fields: [ALEX_EVENT_DATE, ALEX_EVENT_TITLE],
      filter: filter_text(first_date, last_date)
    )
    all_records.collect do |record|
      AlexEvent.from_record(record)
    end
  end

  def self.events_for_month(year, month_no)
    self.events_for_date_range(
      Date.new(year, month_no, 1),
      Date.new(year, month_no, -1)
    )
  end

  def self.has_event_for_date?(date)
    !self.event_for_date(date).nil?
  end

  def self.event_for_date(date)
    es = self.events_for_date_range(date, date)
    if es.empty?
      nil
    elsif es.len == 1
      es[0]
    else
      raise "Unexpected events for date #{date}, #{es}"
    end
  end
end


