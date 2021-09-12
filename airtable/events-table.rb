require_relative '../env'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

class EventRecord
  attr_reader :event_date, :event_title, :record_id, :gig_code
  def initialize(record_id, gig_code, event_date, event_title)
    @record_id = record_id
    @gig_code = gig_code
    @event_date = event_date
    @event_title = event_title
  end

  def self.from_record(record)
    record_id = record.id
    gig_code = record[GIG_CODE]
    event_date = Date.parse(record[EVENT_DATE])
    event_title = record[EVENT_TITLE]
    EventRecord.new(record_id, gig_code, event_date, event_title)
  end

  def to_s()
    "#{@gig_code}, #{@event_title}, #{@event_date}"
  end
end

class EventRecords
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


class OriginalContract
  attr_reader :performance_date, :event_title

  def initialize(record_id, performance_date, event_title)
    @performance_date = performance_date
    @event_title = event_title
  end

  def self.from_record(record)
    record_id = record.id
    performance_date = Date.parse(record[PERFORMANCE_DATES])
    event_title = record[EVENT_TITLE]
    OriginalContract.new(record_id, performance_date, event_title)
  end

  def to_s()
    "#{@event_title}, #{@performance_date}"
  end
end

class OriginalContractsTable < Airrecord::Table
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = CONTRACTS_TABLE

  def self.all_contracts()
    all_records = OriginalContractsTable.all(
      fields: [EVENT_TITLE, PERFORMANCE_DATES],
    ).filter do |rec|
      begin
        Date.parse(rec[PERFORMANCE_DATES])
        true
      rescue
        false
      end
    end

    
    all_records.collect do |record|
      OriginalContract.from_record(record)
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
    OriginalContract.new(record_id, event_date, event_title)
  end

  def to_s()
    "#{@event_title}, #{@event_date}"
  end
end

class AlexEvents < Airrecord::Table
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

  def self.events_for_date_range(first_date, last_date)
    first_date_formatted = first_date.strftime("%Y-%m-%d")
    last_date_formatted = last_date.strftime("%Y-%m-%d")
    all_records = AlexEvents.all(
      fields: [ALEX_EVENT_DATE, ALEX_EVENT_TITLE],
      filter: "AND({#{ALEX_EVENT_DATE}} >= '#{first_date_formatted}',{#{ALEX_EVENT_DATE}} <= '#{last_date_formatted}')"
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


