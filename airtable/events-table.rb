require_relative '../env'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

class EventRecord
  attr_reader :event_date, :event_title
  def initialize(gig_code, event_date, event_title)
    @gig_code = gig_code
    @event_date = event_date
    @event_title = event_title
  end

  def self.from_record(record)
    gig_code = record[GIG_CODE]
    event_date = Date.parse(record[EVENT_DATE])
    event_title = record[EVENT_TITLE]
    EventRecord.new(gig_code, event_date, event_title)
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




class AlexEvents < Airrecord::Table
  self.base_key = ALEX_TEST_BASE_KEY
  self.table_name = ALEX_EVENTS_TABLE


  def self.events_for_month(year, month_no)
    first_date = Date.new(year, month_no, 1).strftime("%Y-%m-%d")
    last_date = Date.new(year, month_no, -1).strftime("%Y-%m-%d")
    all_records = AlexEvents.all(
      fields: [EVENT_DATE, EVENT_TITLE, GIG_CODE],
      filter: "AND({#{EVENT_DATE}} >= '#{first_date}',{#{EVENT_DATE}} <= '#{last_date}')"
    )
    all_records.collect do |record|
      EventRecord.from_record(record)
    end
  end
end

