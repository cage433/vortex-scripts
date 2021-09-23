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

class GigPersonnel 
  include SimpleEqualityMixin
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

class Event 
  include SimpleEqualityMixin
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

class DatedCollection 
  include SimpleEqualityMixin
  attr_reader :data, :size, :data_by_date, :dates

  def initialize(data)
    @data = data.sort_by { |e| e.date }
    @data_by_date = Hash[ *data.collect { |e| [e.date, e ] }.flatten ]
    @size = data.size
    @dates = @data_by_date.keys.sort

    data.each { |e|
      raise "Invalid data" unless e.class == Event || e.class == NightManagerEvent
    }

  end

  def merge(rhs)
    merged_data = [*@data]
    rhs.data.each do |data|
      if !include?(data.date)
        merged_data.push(data)
      end
    end
    DatedCollection.new(merged_data)
  end

  def include?(date)
    @data_by_date.include?(date)
  end

  def [](date)
    @data_by_date[date]
  end

  def +(rhs)
    @data_by_date.keys.each { |d|
      raise "Both sides contain date #{d}" if rhs.include?(d)
    }
    DatedCollection.new(data + rhs.data)
  end

  def changed_data(rhs)
    raise "Event date mismatch, #{@dates}, #{rhs.dates}" unless @dates == rhs.dates

    DatedCollection.new(
      @dates.filter { |d| 
        @data_by_date[d] != rhs.data_by_date[d]
      }.collect { |d|
        @data_by_date[d]
      }
    )
  end

  def diff_by_date(rhs)
    DatedCollection.new(
      @data.filter{ |e| 
        !rhs.data_by_date.include?(e.date)
      }
    )
  end

  def state
    @data
  end

end
