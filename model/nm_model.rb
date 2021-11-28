require_relative '../utils/utils'

class NumberSoldAndValue
  attr_reader :number, :value

  def initialize(number:, value:)
    @number = number.to_i
    @value = value.to_f
  end

  def to_s
    "Sold #{number} for #{value}"
  end
end

class NMForm_SessionData
  attr_reader :mugs, :t_shirts, :masks, :bags, :zettle_z_reading, :cash_z_reading, :notes, :fee_to_pay, :prs_to_pay

  def initialize(mugs:, t_shirts:, masks:, bags:, zettle_z_reading:, cash_z_reading:, notes:, fee_to_pay:, prs_to_pay:)
    [mugs, t_shirts, masks, bags].each do |merch|
      assert_type(merch, NumberSoldAndValue)
    end
    @mugs = mugs
    @t_shirts = t_shirts
    @masks = masks
    @bags = bags
    @zettle_z_reading = zettle_z_reading.to_f
    @cash_z_reading = cash_z_reading.to_f
    @notes = notes
    @fee_to_pay = fee_to_pay.to_f
    @prs_to_pay = prs_to_pay.to_f
  end

  def to_s
    [
      "Session",
      " Mugs: #{@mugs}",
      " T-shirts: #{@t_shirts}",
      " Masks: #{@masks}",
      " Bags: #{@bags}",
      " Zettle: #{@zettle_z_reading}",
      " Cash: #{@cash_z_reading}",
      " Notes: #{@notes}",
      " Fee To Pay: #{@fee_to_pay}",
      " PRS To Pay: #{@prs_to_pay}",
    ].join("\n")
  end
end

class NMForm_GigData
  attr_reader :performance_date, :gig, :online, :walk_ins, :guests_and_cheap

  def initialize(gig:, online:, walk_ins:, guests_and_cheap:)
    [online, walk_ins, guests_and_cheap].each do |x|
      assert_type(x, NumberSoldAndValue)
    end
    @gig = gig
    @online = online
    @walk_ins = walk_ins
    @guests_and_cheap = guests_and_cheap
  end

  def to_s
    terms = [
      @gig,
      "Online: #{@online}",
      "Walkins: #{@walk_ins}",
      "Guests/cheap: #{@guests_and_cheap}",
    ]
  end
end

class NMForm_ExpensesData
  attr_reader :note, :amount

  def initialize(note:, amount:)
    @note = note
    @amount = amount.to_f
  end

  def to_s
    "  Expense: #{@note}, #{@amount}"
  end
end

class NMForm_Data
  attr_reader :date, :session_data, :gigs_data, :expenses_data
  def initialize(date:, session_data:, gigs_data:, expenses_data:)
    assert_type(date, Date)
    assert_type(session_data, NMForm_SessionData)
    assert_collection_type(gigs_data, NMForm_GigData)
    assert_collection_type(expenses_data, NMForm_ExpensesData)
    @date = date
    @session_data = session_data
    @gigs_data = gigs_data
    @expenses_data = expenses_data
  end
  def to_s
    terms = [
      "Form",
      @session_data.to_s,
      "", "Expenses",
    ] + @expenses_data.collect{ |e| e.to_s} + ["", "Gigs"] + @gigs_data.collect{ |g| g.to_s}
    terms.join("\n")
  end
end
