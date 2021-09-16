require_relative '../../model/model'
require_relative '../../mediator/mediator'

def assert_dimension_2d(arr, expected_rows, expected_cols)
  raise "Row dimension mismatch, expected #{expected_rows}, got #{arr.size}" if arr.size != expected_rows
  arr.each do |row|
  raise "Col dimension mismatch, expected #{expected_cols}, got #{row.size}" if row.size != expected_cols
  end
end



class VolunteerSheetDetailsForMonth
  def initialize(event_details)
    @event_details = event_details
    @events_by_date = Hash[ *event_details.collect { |e| [e.event_date, e ] }.flatten ]
  end

  def num_events
    @event_details.size
  end

  def sorted()
    @event_details.sort_by { |a| a.event_date}
  end

  def add_missing_airtable_events(airtable_events)
    merged_events = [*@event_details]
    airtable_events.events.each do |airtable_event|
      if !@events_by_date.has_key?(airtable_event.event_date)
        merged_events.push(
          EventDetailsMediator.from_airtable_record(airtable_event)
        )
      end
    end
    VolunteerSheetDetailsForMonth.new(merged_events)
  end
end
