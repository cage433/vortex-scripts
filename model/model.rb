class SimpleEquals
  def ==(o)
    o.class == self.class && o.state == self.state
  end
end

class Gig < SimpleEquals
  attr_reader :airtable_id, :gig_no, :vol1, :vol2, :night_manager

  def initialize(airtable_id:, gig_no:, vol1:, vol2:, night_manager:)
    @airtable_id = airtable_id
    @gig_no = gig_no
    @vol1 = vol1
    @vol2 = vol2
    @night_manager = night_manager
  end

  def state
    [@airtable_id, @gig_number, @vol1, @vol2, @night_manager]
  end
end

class Event < SimpleEquals
  attr_reader :airtable_id, :event_date, :event_title, :gig1, :gig2, :sound_engineer

  def initialize(airtable_id:, event_date:, event_title:, gig1:, gig2:, sound_engineer:)
    @airtable_id = airtable_id
    @event_date = event_date
    @event_title = event_title
    @gig1 = gig1
    @gig2 = gig2
    @sound_engineer = sound_engineer
  end

  def to_s()
"#{@event_date}: #{@event_title}
  Gig1: #{gig1}
  Gig2: #{gig1}
  SE: <#{@sound_engineer}>
"
  end


  def state
    [@airtable_id, @event_date, @event_title, @gig1, @gig2, @sound_engineer]
  end
end

class EventsForMonth
  attr_reader :year, :month, :events, :num_events

  def initialize(year, month, events)
    @year = year
    @month = month
    @events = events
    @events_by_date = Hash[ *events.collect { |e| [e.event_date, e ] }.flatten ]
    @num_events = events.size

  end

  def sorted_events()
    @events.sort_by { |a| a.event_date}
  end


  def merge(rhs)
    merged_events = [*@events]
    rhs.events.each do |event|
      if !@events_by_date.has_key?(event.event_date)
        merged_events.push(event)
      end
    end
    EventsForMonth.new(@year, @month, merged_events)
  end

end
