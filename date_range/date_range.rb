require 'date'
class AbstractDateRange
  def to_s
    "#{self.class} #{first_date} - #{last_date}"
  end
end

class Month < AbstractDateRange
  attr_reader :year_no, :month_no

  def initialize(year_no:, month_no:)
    @year_no = year_no
    @month_no = month_no
  end

  def first_date
    Date.new(@year_no, @month_no, 1)
  end

  def last_date
    Date.new(@year_no, @month_no, -1)
  end

  def +(inc)
    y = @year_no
    m = @month_no + inc
    while m > 12 do
      y += 1
      m -= 12
    end
    while m < 1 do
      y -= 1
      m += 12
    end
    Month.new(year_no: y, month_no: m)
  end

  def -(dec)
    self + (-dec)
  end

  def ==(other)
    other.is_a?(Month) && other.year_no == @year_no && other.month_no == @month_no
  end
end

class Week < AbstractDateRange
  attr_reader :year_no, :week_number
  def to_s
    "#{self.class}, #{@year_no} #{@week_number}: #{first_date} - #{last_date}"
  end

  def initialize(year_no:, week_number:)
    @year_no = year_no
    @week_number = week_number
    raise "Invalid week #{week_number} for year #{year_no}" unless \
      week_number >= 1 && week_number <= Week.last_week_number_of_year(year_no: year_no)
  end

  def first_date
    Week.start_of_first_week(year_no: @year_no) + (@week_number - 1) * 7
  end
  def last_date
    first_date + 6
  end

  def self.start_of_first_week(year_no:)
    d = Date.new(year_no, 9, 1)
    while d.cwday > 5 do
      d += 1
    end
    while d.cwday != 1 do
      d -= 1
    end
    d
  end

  def friday
    first_date + 4
  end

  def self.last_week_number_of_year(year_no:)
    d0 = self.start_of_first_week(year_no: year_no)
    d = Date.new(year_no + 1, 8, -1)
    while d.cwday != 5 do
      d -= 1
    end
    d -= 4
    (d - d0) / 7 + 1
  end

  def self.containing(d)
    y = d.year
    if Week.start_of_first_week(year_no: y) > d
      y -= 1
    end
    monday = d - d.cwday + 1
    week_number = ((monday - Week.start_of_first_week(year_no: y)) / 7).to_i + 1

    Week.new(year_no: y, week_number: week_number)
  end

  def next
    if @week_number < Week.last_week_number_of_year(year_no: @year_no)
      Week.new(year_no: @year_no, week_number: @week_number + 1)
    else
      Week.new(year_no: @year_no + 1, week_number: 1)
    end
  end
  def previous
    if @week_number > 1
      Week.new(year_no: @year_no, week_number: @week_number - 1)
    else
      Week.new(year_no: @year_no - 1, week_number: Week.last_week_number_of_year(year_no: @year_no - 1))
    end
  end

  def +(inc)
    week = self
    if inc >= 0
      inc.abs.times do
        week = week.next
      end
    else
      inc.abs.times do
        week = week.previous
      end
    end
    week
  end

  def -(dec)
    self + (-dec)
  end

  def ==(other)
    other.is_a?(Week) && other.year_no == @year_no && other.week_number == @week_number
  end
end

class WeekReport
  attr_reader :week, :audience_number, :advance_ticket_sales, :card_ticket_sales, :cash_ticket_sales
  def initialize(week:, audience_number:, advance_ticket_sales:, card_ticket_sales:, cash_ticket_sales:)
    @week = week
    @audience_number = audience_number
    @advance_ticket_sales = advance_ticket_sales
    @card_ticket_sales = card_ticket_sales
    @cash_ticket_sales = cash_ticket_sales
  end
end

class DateRange < AbstractDateRange
  attr_reader :first_date, :last_date
  def initialize(first_date:, last_date:)
    @first_date = first_date
    @last_date = last_date
  end
end

class DateRangeIterator
  attr_reader :first_date, :last_date
  def initialize(first_date:, last_date:)
    @first_date = first_date
    @last_date = last_date
  end

  def each(&block)
    while @first_date <= @last_date do
      block.call(@first_date)
      @first_date += 1
    end
  end
end

class DateRangeEnumerator
  attr_reader :first_date, :last_date
  def initialize(first_date:, last_date:)
    @first_date = first_date
    @last_date = last_date
  end

  def each(&block)
    while @first_date <= @last_date do
      block.call(@first_date)
      @first_date += 1
    end
  end
end

class DateRangeEnumerator2
  attr_reader :first_date, :last_date
  def initialize(first_date:, last_date:)
    @first_date = first_date
  end
end

class WeekReport
  attr_reader :week, :audience_number, :advance_ticket_sales, :card_ticket_sales, :cash_ticket_sales
  def initialize(week:, audience_number:, advance_ticket_sales:, card_ticket_sales:, cash_ticket_sales:)
    @week = week
    @audience_number = audience_number
    @advance_ticket_sales = advance_ticket_sales
    @card_ticket_sales = card_ticket_sales
    @cash_ticket_sales = cash_ticket_sales
  end
end

class WeekReportController
  def initialize(year_no:, month_no:)
    @year_no = year_no
    @month_no = month_no
  end

  def week_reports
    weeks.map { |week|
      WeekReport.new(
        week: week,
        audience_number: audience_number(week),
        advance_ticket_sales: advance_ticket_sales(week),
        card_ticket_sales: card_ticket_sales(week),
        cash_ticket_sales: cash_ticket_sales(week)
      )
    }
  end

  def weeks
    first_week = Week.new(year_no: @year_no, week_number: 1)
    last_week = Week.last_week_of_year(year_no: @year_no)
    (first_week..last_week).step(7)
  end

  def audience_number(week)
    week.first_date.cwday == 1 ? 0 : 1
  end

  def advance_ticket_sales(week)
    week.first_date.cwday == 1 ? 0 : 1
  end

  def card_ticket_sales(week)
    week.first_date.cwday == 1 ? 0 : 1
  end

end
class VortexWeek < AbstractDateRange
  attr_reader :month, :week_number, :first_day, :last_day

  def initialize(month:, week_number:, first_date:, last_date:)
    @month = month
    @week_number = week_number
    @first_date = first_date
    @last_date = last_date
  end

  def first_date
    @first_date
  end

  def last_date
    @last_date
  end

  WEEK_40_JUN_22 = VortexWeek.new(
    month: Month.new(year_no: 2022, month_no: 6),
    week_number: 40,
    first_date: Date.new(2022, 5, 30),
    last_date: Date.new(2022, 6, 5)
  )
  WEEK_41_JUN_22 = VortexWeek.new(
    month: Month.new(year_no: 2022, month_no: 6),
    week_number: 41,
    first_date: Date.new(2022, 6, 6),
    last_date: Date.new(2022, 6, 12)
  )
end

class DateRange < AbstractDateRange
  def initialize(first_date:, last_date:)
    @first_date = first_date
    @last_date = last_date
  end
end