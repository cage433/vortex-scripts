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