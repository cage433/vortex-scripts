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

class GigTakings < SimpleEquals
  attr_reader :airtable_id, :gig_no, 
    :online_tickets, :ticket_price, 
    :walk_ins, :walk_in_sales, 
    :t_shirts, :t_shirt_sales,
    :mugs, :mugs_sales,

  def initialize(
    airtable_id:, gig_no:, 
    online_tickets:, ticket_price:, 
    walk_ins:, walk_in_sales:, 
    t_shirts:, t_shirt_sales:,
    mugs:, mug_sales:
  )
    @airtable_id = airtable_id
    @gig_no = gig_no
    @online_tickets = online_tickets
    @ticket_price = ticket_price
    @walk_in = walk_ins
    @walk_in_sales = walk_in_sales
    @t_shirts = t_shirts
    @t_shirt_sales = t_shirts_sales
    @mugs = mugs
    @mug_sales = mug_sales
  end

  def state
    [ 
      @airtable_id, @gig_no, @num_online_tickets, @full_price,
      @walk_in_num, @walk_in_sales, @mugs_num, @mugs_sales,
    ]
  end

end

class NightManagerEvent
  attr_reader :airtable_id, :gig1_takings, :gig2_takings

  def initialize(airtable_id:, gig1_takings:, gig2_takings:)
    @airtable_id = airtable_id
    @gig1_takings = gig1_takings
    @gig2_takings = gig2_takings
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
