class Month
  attr_reader :year_no, :month_no
  def initialize(
    year_no:,
    month_no:
  )
    @year_no = year_no
    @month_no = month_no
  end

  def to_s
    "#{year_no}-#{month_no}"
  end
end

class Week
  attr_reader :month, :week_number, :first_day, :last_day
  def initialize(
    month:,
    week_number:,
    first_day:,
    last_day:
  )
    @month = month
    @week_number = week_number
    @first_day = first_day
    @last_day = last_day

  end

  def to_s
    "#{month} #{week_number}: #{first_day} - #{last_day}"
  end

  # WEEK_40_JUN_22 = Week.new(
  #   month: Month.new(year_no: 2022, month_no: 6),
  #   week_number: 40,
  #   first_day: Date.new(2022, 5, 30),
  #   last_day: Date.new(2022, 6, 5)
  # )
  #
end

class WeekReport
  def initialize(
    week:,
    audience_number:,
    advance_ticket_sales:,
    card_ticket_sales:,
    cash_ticket_sales:
  )
    @week = week
    @audience_number = audience_number
    @advance_ticket_sales = advance_ticket_sales
    @card_ticket_sales = card_ticket_sales
    @cash_ticket_sales = cash_ticket_sales
  end
end
