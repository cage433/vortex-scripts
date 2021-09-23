def transform(x)
  # Where the DB returns nils, excel will return blanks
  # ditto for float/ints
  if x.nil?
    ''
  elsif x.class == Integer
    x.to_f
  else
    x
  end
end
class SimpleEquals
  def ==(o)
    if self.state.size != o.state.size
      false
    else
      self.state.zip(o.state).all? { |a, b|
        transform(a) == transform(b)
      }
    end
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

class FeeDetails < SimpleEquals
  attr_reader :fee_notes, :flat_fee, :minimum_fee, :fee_percentage
  def initialize(
    fee_notes:, flat_fee:, minimum_fee:, fee_percentage:
  )
    @fee_notes = fee_notes
    @flat_fee = flat_fee
    @minimum_fee = minimum_fee
    @fee_percentage = fee_percentage
  end

  def to_s_table(indent)
    table = [
      "Fee Notes: #{@fee_notes}",
      "Flat Fee: #{@flat_fee}",
      "Min Fee: #{@minimum_fee}",
      "Fee %age: #{@fee_percentage}",
    ]
    table.collect { |t| "#{indent}#{t}" }
  end

  def state
    [@fee_notes, @flat_fee, @minimum_fee, @fee_percentage]
  end
end

class NightManagerEvent < SimpleEquals
  attr_reader :airtable_id, :date, :title, 
    :fee_details,
    :gig1_takings, :gig2_takings

  def initialize(
    airtable_id:, 
    date:, title:, 
    fee_details:,
    gig1_takings:, gig2_takings:
  )
    @airtable_id = airtable_id
    @date = date
    @title = title
    @fee_details = fee_details
    @gig1_takings = gig1_takings
    @gig2_takings = gig2_takings
  end

  def to_s_table(indent)
    table = [
      "Date:     #{@date}",
      "Title:    #{@title}",
      "Fee Details:"
    ] +
      @fee_details.to_s_table(indent + "    ") +
    ["Gig 1"] + 
      @gig1_takings.to_s_table(indent + "    ") +
    ["Gig 2"] + 
      @gig2_takings.to_s_table(indent + "    ")
    table.collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("  ").join("\n")
  end

  def state
    [@airtable_id, @date, @title, @fee_details, @gig1_takings, @gig2_takings]
  end

  def update_gig1_ticket_price(price)
    @gig1_takings.update_ticket_price(price)
  end

  def update_gig2_ticket_price(price)
    @gig2_takings.update_ticket_price(price)
  end

  def update_fee_details(new_fee_details)
    @fee_details = new_fee_details
  end
end

class Event < SimpleEquals
  attr_reader :airtable_id, :date, :title, :gig1, :gig2, :sound_engineer

  def initialize(airtable_id:, date:, title:, gig1:, gig2:, sound_engineer:)
    @airtable_id = airtable_id
    @date = date
    @title = title
    @gig1 = gig1
    @gig2 = gig2
    @sound_engineer = sound_engineer
  end

  def to_s()
"#{@date}: #{@title}
  Gig1: #{gig1}
  Gig2: #{gig1}
  SE: <#{@sound_engineer}>
"
  end


  def state
    [@airtable_id, @date, @title, @gig1, @gig2, @sound_engineer]
  end
end

class EventsCollection < SimpleEquals
  attr_reader :events, :num_events, :events_by_date, :dates

  def initialize(events)
    @events = events.sort_by { |e| e.date }
    @events_by_date = Hash[ *events.collect { |e| [e.date, e ] }.flatten ]
    @num_events = events.size
    @dates = @events_by_date.keys.sort

    events.each { |e|
      raise "Invalid event" unless e.class == Event || e.class == NightManagerEvent
    }

  end

  def sorted_events()
    @events.sort_by { |a| a.date}
  end


  def merge(rhs)
    merged_events = [*@events]
    rhs.events.each do |event|
      if !@events_by_date.has_key?(event.date)
        merged_events.push(event)
      end
    end
    EventsCollection.new(merged_events)
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
    EventsCollection.new(events + rhs.events)
  end

  def changed_events(rhs)
    raise "Event date mismatch, #{@dates}, #{rhs.dates}" unless @dates == rhs.dates

    EventsCollection.new(
      @dates.filter { |d| 
        @events_by_date[d] != rhs.events_by_date[d]
      }.collect { |d|
        @events_by_date[d]
      }
    )
  end

  def diff_by_date(rhs)
    EventsCollection.new(
      @events.filter{ |e| 
        !rhs.events_by_date.include?(e.date)
      }
    )
  end

  def state
    @events
  end

end
