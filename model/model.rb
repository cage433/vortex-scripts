require_relative '../utils/utils'

module SimpleEqualityMixin
  # Used to compare DB and spreadsheet versions of objects
  #
  # Classes which use this mixin provide a `state` method which is
  # used to compare objects. 
  # 
  # Ignores differences due to nulls/empty strings and floats/int representations
  # of the same number

  def _transform(x)
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
  def ==(o)
    if self.state.size != o.state.size
      false
    else
      self.state.zip(o.state).all? { |a, b|
        _transform(a) == _transform(b)
      }
    end
  end

  def compare(rhs)
    # Utility for when DB/sheet unexpectedly mismatch
    raise "Mismatching state size" unless state.size == rhs.state.size
    state.zip(rhs.state).each do |l, r|
      if l.class == SimpleEqualityMixin
        puts("#{l.class}, #{r.class}, #{transform(l) == transform(r)}")
        l.compare(r)
      else
        puts("#{l}, #{r}, #{l.class}, #{r.class}, #{transform(l) == transform(r)}")
      end
    end
  end

  def state
    raise "Mixed-in class must provide its own implementation of `state`" 
  end
end

class EventPersonnel 
  #include SimpleEqualityMixin
  attr_reader :airtable_id, :title, :date, :doors_open, :vol1, :vol2, :night_manager, :sound_engineer

  def initialize(airtable_id:, title:, date:, doors_open:, vol1:, vol2:, night_manager:, sound_engineer:)
    assert_type(doors_open, Time, allow_null: true)
    @airtable_id = airtable_id
    @title = title
    @date = date
    @doors_open = doors_open
    @vol1 = vol1
    @vol2 = vol2
    @night_manager = night_manager
    @sound_engineer = sound_engineer
  end

  #def state
    #[@airtable_id, @title, @date, @doors_open, @vol1, @vol2, @night_manager, @sound_engineer]
  #end

  def to_s_table(indent)
    [
      "Title:           #{@title}",
      "Date:            #{@date}",
      "Doors:           #{@doors_open}",
      "Vol1:            #{@vol1}",
      "Vol2:            #{@vol2}",
      "NM:              #{@night_manager}",
      "SE:              #{@sound_engineer}",
    ].collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("")
  end

  def personnel_match(rhs)
    raise "Mismatching ids" unless airtable_id == rhs.airtable_id
    EventPersonnel.states_match(personnel_state, rhs.personnel_state)
  end

  def metadata_match(rhs)
    EventPersonnel.states_match(metadata_state, rhs.metadata_state)
  end

  def state
    [@title, @date, @doors_open, @vol1, @vol2, @night_manager, @sound_engineer, @sound_engineer]
  end

  def matches(rhs)
    EventPersonnel.states_match(state, rhs.state)
  end

  def personnel_state
    [@vol1, @vol2, @night_manager, @sound_engineer]
  end

  def metadata_state
    [@title, @date, @doors_open, @sound_engineer]
  end

  def with_metadata_from(rhs)
    EventPersonnel.new(
      airtable_id:    @airtable_id,
      title:          rhs.title,
      date:           rhs.date, 
      doors_open:     rhs.doors_open,
      vol1:           @vol1,
      vol2:           @vo2,
      night_manager:  @night_manager,
      sound_engineer: rhs.sound_engineer
    )
  end

  def self.states_match(l, r)
    raise "State lengths differ" unless l.size == r.size
    l.zip(r).all? { |l, r|
      is_equal_ignoring_nil_or_blank?(l, r)
    }
  end
end

class EventsPersonnel
  attr_reader :events_personnel, :airtable_ids
  def initialize(events_personnel:)
    assert_collection_type(events_personnel, EventPersonnel)
    @events_personnel = events_personnel
    @events_personnel_by_id = Hash[ *events_personnel.collect { |e| [e.airtable_id, e ] }.flatten ]
    @airtable_ids = events_personnel.collect{ |p| p.airtable_id }.sort
  end
  
  def [](id)
    @events_personnel_by_id[id]
  end

  def include?(id)
    @events_personnel_by_id.include?(id)
  end

  def add_missing(rhs)
    merged_events_personnel = [*@events_personnel]
    rhs.events_personnel.each do |ep|
      if !include?(ep.airtable_id)
        merged_events_personnel.push(ep)
      end
    end
    EventsPersonnel.new(events_personnel: merged_events_personnel)
  end

  def size
    @events_personnel.size
  end

  def changed_personnel(rhs)
    assert_type(rhs, EventsPersonnel)
    EventsPersonnel.new(
      events_personnel: @events_personnel.filter { |ep| !ep.personnel_match(rhs[ep.airtable_id]) }
    )
  end

  def matches(rhs)
    assert_type(rhs, EventsPersonnel)
    if @airtable_ids != rhs.airtable_ids
      false
    else 
      @airtable_ids.all? { |id| @events_personnel_by_id[id].matches(rhs[id])}
    end
  end
end


class GigTakings 
  include SimpleEqualityMixin
  attr_reader :airtable_id, :gig_no, :vol1, :vol2, :night_manager
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

class FeeDetails 
  include SimpleEqualityMixin
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

class NightManagerEvent 
  include SimpleEqualityMixin
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

