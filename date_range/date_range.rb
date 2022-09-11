require 'date'
require 'csv'
require_relative '../utils/utils'
class AbstractDateRange
  def to_s
    "#{self.class} #{first_date} - #{last_date}"
  end
  def contains?(date)
    assert_type(date, Date)
    date >= first_date && date <= last_date
  end
end

class Month < AbstractDateRange
  include Comparable
  attr_reader :accounting_year, :month_no

  def initialize(year_no, month_no)
    @year_no = year_no
    @month_no = month_no
    raise "Invalid month #{year_no}/#{month_no}" if @month_no < 1 || @month_no > 12
    raise "Invalid month #{year_no}/#{month_no}" if @year_no < 2010 || @year_no > 2030
  end

  def self.containing(date)
    Month.new(date.year, date.month)
  end

  def to_s
    "#{@year_no}/#{@month_no}"
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
    Month.new(y, m)
  end

  def -(dec)
    self + (-dec)
  end

  def <=>(other)
    assert_type(other, Month)
    [@year_no, @month_no] <=> [other.accounting_year, other.month_no]
  end

  alias :eql? :==

  def tab_name
    Date.new(@year_no, @month_no, 1).strftime("%B %y")
  end

  def hash
    17 * @year_no + @month_no
  end

end

class AccountingYear < AbstractDateRange
  attr_reader :accounting_year, :first_date, :last_date

  def initialize(year_no)
    @year_no = year_no
    @first_date = Month.new(year_no - 1, 9).first_week.first_date
    @last_date = Month.new(year_no, 8).last_week.last_date
  end

  def vortex_week_range
    DateRange.new(@first_date, @last_date)
  end

  def tab_name
    @year_no.to_s
  end
end

class AccountingMonth < AbstractDateRange
  include Comparable
  attr_reader :accounting_year, :month_no

  def initialize(accounting_year, month_no)
    @accounting_year = accounting_year
    @month_no = month_no
    raise "Invalid month #{accounting_year}/#{month_no}" if @month_no < 1 || @month_no > 12
    raise "Invalid month #{accounting_year}/#{month_no}" if @accounting_year < 2010 || @accounting_year > 2030
  end

  def first_week
    if MONTHS_TO_FIRST_WEEK.include?(self )
      MONTHS_TO_FIRST_WEEK[self]
    else
      d = Month(@accounting_year, @month_no, 1)
      while d.cwday != 5 do
        d += 1
      end
      Week.containing(d)
    end
  end

  def self.containing(date)
    m = AccountingMonth.new(date.year, date.month) - 1
    while !m.contains?(date) do
      m += 1
    end

  end

  def to_s
    "#AccMth-{@year_no}/#{@month_no}"
  end

  def first_date
    first_week.first_date
  end

  def last_date
    last_week.last_date
  end

  def +(inc)
    y = @accounting_year
    m = @month_no + inc
    while m > 12 do
      y += 1
      m -= 12
    end
    while m < 1 do
      y -= 1
      m += 12
    end
    AccountingMonth.new(y, m)
  end

  def -(dec)
    self + (-dec)
  end

  def <=>(other)
    assert_type(other, AccountingMonth)
    [@accounting_year, @month_no] <=> [other.accounting_year, other.month_no]
  end

  alias :eql? :==

  def tab_name
    Date.new(@accounting_year, @month_no, 1).strftime("%B %y")
  end

  def weeks
    result = []
    w = first_week

    while w <= last_week do
      result << w
      w += 1
    end
    result
  end

  def last_week
    (self + 1).first_week - 1
  end

  def hash
    19 * @accounting_year + @month_no
  end

  def self.parse(text)
    mth_name = text[0..2]
    mth_no = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"].index(mth_name) + 1
    year_no = 2000 + text[4..5].to_i
    AccountingMonth.new(year_no, mth_no)
  end

end

class Week < AbstractDateRange
  include Comparable
  attr_reader :accounting_year, :week_number
  def to_s
    "#{self.class}, #{@accounting_year} #{@week_number}: #{first_date} - #{last_date}"
  end

  def initialize(accounting_year, week_number)
    @accounting_year = accounting_year
    @week_number = week_number
  end

  def first_date
    Week.start_of_first_week(accounting_year: @accounting_year) + (@week_number - 1) * 7
  end

  def last_date
    first_date + 6
  end

  def self.start_of_first_week(accounting_year:)
    d = Date.new(accounting_year - 1, 9, 1)
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

  def self.last_week_number_of_year(accounting_year:)
    d0 = self.start_of_first_week(accounting_year: accounting_year)
    d1 = self .start_of_first_week(accounting_year: accounting_year + 1)
    (d1 - d0) / 7 + 1
  end

  def self.containing(d)
    y = d.year
    if Week.start_of_first_week(accounting_year: y) > d
      y -= 1
    end
    monday = d - d.cwday + 1
    week_number = ((monday - Week.start_of_first_week(accounting_year: y)) / 7).to_i + 1

    Week.new(y, week_number)
  end

  def next
    if @week_number < Week.last_week_number_of_year(accounting_year: @accounting_year)
      Week.new(@accounting_year, @week_number + 1)
    else
      Week.new(@accounting_year + 1, 1)
    end
  end
  def previous
    if @week_number > 1
      Week.new(@accounting_year, @week_number - 1)
    else
      Week.new(@accounting_year - 1, Week.last_week_number_of_year(accounting_year: @accounting_year - 1))
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

  def <=>(other)
    assert_type(other, Week)
    [@accounting_year, @week_number] <=> [other.accounting_year, other.week_number]
  end


end

def read_months_to_first_week
  path = File.join(
    File.dirname(__FILE__), '..', 'data', 'VortexWeeks.csv'
  )
  data = CSV.readlines(path).drop(1)
  month_to_first_week = {}
  data.each { |row|

    if row[0].nil? || row[0].strip == ""
      next
    end
    week_number = row[1].to_i
    month = AccountingMonth.parse(row[2])
    week = Week.new(month.accounting_year, week_number)
    if month_to_first_week[month].nil?
      month_to_first_week[month] = week
    end
  }
  month_to_first_week
end

MONTHS_TO_FIRST_WEEK = read_months_to_first_week

class DateRange < AbstractDateRange
  attr_reader :first_date, :last_date
  def initialize(first_date, last_date)
    @first_date = first_date
    @last_date = last_date
  end
end

class Year < AbstractDateRange
  attr_reader :accounting_year, :first_date, :last_date

  def initialize(year_no)
    @year_no = year_no
    @first_date = Date.new(year_no, 1, 1)
    @last_date = Date.new(year_no, 12, 31)
  end

  def tab_name
    @year_no.to_s
  end
end


