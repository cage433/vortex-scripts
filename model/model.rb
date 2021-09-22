class SimpleEquals
  def ==(o)
    # Where the DB returns nils, excel will return blanks
    self.state.zip(o.state).all? { |a, b|
      (a || '') == (b || '')
    }
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

  def to_s()
    "  Gig Personnel: #{@airtable_id}, #{@gig_no}, #{@vol1}, #{@vol2}, #{@night_manager}"
  end
end


class GigTakings < SimpleEquals
  attr_reader :airtable_id, :gig_no, 
    :online_tickets, :ticket_price,
    :walk_ins, :walk_in_sales, 
    :guests_or_cheap, :guest_or_cheap_sales, 
    :t_shirts, :t_shirt_sales,
    :mugs, :mug_sales

  def initialize(
    airtable_id:, gig_no:, online_tickets:, ticket_price:, 
    walk_ins:, walk_in_sales:, 
    guests_or_cheap:, guest_or_cheap_sales:, 
    t_shirts:, t_shirt_sales:, 
    mugs:, mug_sales:
  )
    @airtable_id = airtable_id
    @gig_no = gig_no
    @online_tickets = online_tickets
    @ticket_price = ticket_price
    @walk_ins = walk_ins
    @walk_in_sales = walk_in_sales
    @guests_or_cheap = guests_or_cheap
    @guest_or_cheap_sales = guest_or_cheap_sales
    @t_shirts = t_shirts
    @t_shirt_sales = t_shirt_sales
    @mugs = mugs
    @mug_sales = mug_sales
  end

  def state
    [ 
      @airtable_id, @gig_no, 
      @online_tickets, @ticket_price,
      @walk_ins, @walk_in_sales, 
      @guests_or_cheap, @guest_or_cheap_sales,
      @t_shirts, @t_shirt_sales,
      @mugs, @mug_sales,
    ]
  end

  def to_s_table(indent)
    [
      "Online:          #{@online_tickets} @ #{@ticket_price}",
      "Walk-ins:        #{@walk_ins}, £#{@walk_in_sales}",
      "Guests/cheap:    #{@guests_or_cheap}, £#{@guest_or_cheap_sales}",
      "T-shirts:        #{@t_shirts}, £#{@t_shirt_sales}",
      "Mugs:            #{@mugs}, £#{@mug_sales}"
    ].collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("").join("\n")
  end

  def update_ticket_price(price)
    @ticket_price = price
  end
end

class NightManagerEvent < SimpleEquals
  attr_reader :airtable_id, :event_date, :event_title, 
    :fee_notes, :flat_fee, :minimum_fee, :fee_percentage,
    :gig1_takings, :gig2_takings

  def initialize(
    airtable_id:, 
    event_date:, event_title:, 
    fee_notes:, flat_fee:, minimum_fee:, fee_percentage:,
    gig1_takings:, gig2_takings:
  )
    @airtable_id = airtable_id
    @event_date = event_date
    @event_title = event_title
    @fee_notes = fee_notes
    @flat_fee = flat_fee
    @minimum_fee = minimum_fee
    @fee_percentage = fee_percentage
    @gig1_takings = gig1_takings
    @gig2_takings = gig2_takings
  end

  def to_s_table(indent)
    table = [
      "Date:     #{@event_date}",
      "Title:    #{@event_title}",
      "Fee Notes: #{@fee_notes}",
      "Flat Fee: #{@flat_fee}",
      "Minimum Fee: #{@minimum_fee}",
      "Fee %age: #{@fee_percentage}",
      "Gig 1",
    ] + @gig1_takings.to_s_table(indent + "    ") +
    ["Gig 2"] + @gig2_takings.to_s_table(indent + "    ")
    table.collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("  ").join("\n")
  end

  def state
    [@airtable_id, @event_date, @event_title, @fee_notes, @flat_fee, @minimum_fee, @fee_percentage, 
     @gig1_takings, @gig2_takings]
  end

  def update_gig1_ticket_price(price)
    @gig1_takings.update_ticket_price(price)
  end

  def update_gig2_ticket_price(price)
    @gig2_takings.update_ticket_price(price)
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

class EventsForMonth < SimpleEquals
  attr_reader :year, :month, :events, :num_events, :events_by_date

  def initialize(year, month, events)
    @year = year
    @month = month
    @events = events
    @events_by_date = Hash[ *events.collect { |e| [e.event_date, e ] }.flatten ]
    @num_events = events.size

    events.each { |e|
      raise "Invalid event" unless e.class == Event || e.class == NightManagerEvent
    }

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

  def has_event_for_date?(date)
    @events_by_date.include?(date)
  end

  def event_for_date(date)
    @events_by_date[date]
  end

  def +(rhs)
    @events_by_date.keys.each { |d|
      raise "Both sides contain date #{d}" if rhs.has_event_for_date?(d)
    }
    EventsForMonth.new(@year, @month, events + rhs.events)
  end

  def changed_events(rhs)
    dates = @events_by_date.keys.sort
    r_dates = rhs.events_by_date.keys.sort
    raise "Event date mismatch, #{dates}, #{r_dates}" unless dates == r_dates

    EventsForMonth.new(
      @year, @month,
      dates.filter { |d| 
        l = @events_by_date[d]
        r = rhs.events_by_date[d]
        @events_by_date[d] != rhs.events_by_date[d]
      }.collect { |d|
        @events_by_date[d]
      }
    )
  end

  def diff_by_event_date(rhs)
    EventsForMonth.new(
      @year, @month,
      @events.filter{ |e| 
        !rhs.events_by_date.include?(e.event_date)
      }
    )
  end

  def state
    [@year, @month, @events]
  end

end
