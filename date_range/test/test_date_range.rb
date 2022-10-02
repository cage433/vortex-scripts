require 'minitest/autorun'
require_relative '../date_range'

class TestDateRange < Minitest::Test
  def test_month_addition
    m0 = Month.new(2019, 12)
    m1 = Month.new(2020, 1)
    m2 = Month.new(2020, 2)
    m3 = Month.new(2020, 3)
    assert_equal(m0, m1 - 1)
    assert_equal(m0, m3 - 3)
    assert_equal(m1, m0 + 1)
    assert_equal(m2, m0 + 2)
    assert_equal(m3, m0 + 3)
  end

  def test_accounting_to_calendar_month_round_trip
    for y in 2013..2028 do
      for m in 1..12 do
        am = AccountingMonth.new(y, m)
        cm = am.calendar_month
        assert_equal(am, cm.accounting_month)
      end
    end
  end

  def test_accounting_month_day_contiguity
    m = AccountingMonth.new(2013, 9)
    50.times do |i|
      assert_equal((m - 1).last_date + 1, m.first_date)
      assert_equal((m + 1).first_date - 1, m.last_date)
      m += 1
    end
  end

  #noinspection RubyInstanceMethodNamingConvention
  def test_accounting_year_contiguity
    for y in 2014..2028 do
      ay = AccountingYear.new(y)
      ay2 = AccountingYear.new(y + 1)
      assert_equal(ay + 1, ay2)
      assert_equal(ay.last_date + 1, ay2.first_date)
    end
  end

  def test_week_contiguity
    w = Week.new(2013, 52)
    1000.times do |i|
      assert_equal(w.last_date, (w + 1).first_date - 1)
      d = w.last_date
      while d <= w.last_date do
        assert_equal(w, Week.containing(d))
        d += 1
      end
      w += 1
    end
  end

  def test_weeks_in_accounting_month
    m = AccountingMonth.new(2012, 9)
    50.times do |i|
      assert_equal((m - 1).last_week + 1, m.first_week)
      assert_equal((m + 1).first_week - 1, m.last_week)
      m += 1
    end
  end

  def test_accounting_years_start_and_end
    assert_equal(Date.new(2012, 9, 3), AccountingYear.new(2013).first_date)
    assert_equal(Date.new(2013, 9, 1), AccountingYear.new(2013).last_date)
    assert_equal(Date.new(2013, 9, 2), AccountingYear.new(2014).first_date)
    assert_equal(Date.new(2014, 8, 31), AccountingYear.new(2014).last_date)
    assert_equal(Date.new(2014, 9, 1), AccountingYear.new(2015).first_date)
    assert_equal(Date.new(2015, 8, 30), AccountingYear.new(2015).last_date)
    assert_equal(Date.new(2015, 8, 31), AccountingYear.new(2016).first_date)
    assert_equal(Date.new(2016, 8, 28), AccountingYear.new(2016).last_date)
    assert_equal(Date.new(2016, 8, 29), AccountingYear.new(2017).first_date)
    assert_equal(Date.new(2017, 8, 27), AccountingYear.new(2017).last_date)
    assert_equal(Date.new(2017, 8, 28), AccountingYear.new(2018).first_date)
    assert_equal(Date.new(2018, 9, 2), AccountingYear.new(2018).last_date)
    assert_equal(Date.new(2018, 9, 3), AccountingYear.new(2019).first_date)
    assert_equal(Date.new(2019, 9, 1), AccountingYear.new(2019).last_date)
    assert_equal(Date.new(2019, 9, 2), AccountingYear.new(2020).first_date)
    assert_equal(Date.new(2020, 8, 30), AccountingYear.new(2020).last_date)
    assert_equal(Date.new(2020, 8, 31), AccountingYear.new(2021).first_date)
    assert_equal(Date.new(2021, 8, 29), AccountingYear.new(2021).last_date)
    assert_equal(Date.new(2021, 8, 30), AccountingYear.new(2022).first_date)
    assert_equal(Date.new(2022, 8, 28), AccountingYear.new(2022).last_date)
    assert_equal(Date.new(2022, 8, 29), AccountingYear.new(2023).first_date)

    assert_equal(Date.new(2023, 8, 27), AccountingYear.new(2023).last_date)
    assert_equal(Date.new(2023, 8, 28), AccountingYear.new(2024).first_date)
  end

  def test_acc_years_consistent_with_months
    for y in 2013..2028 do
      ay = AccountingYear.new(y)
      assert_equal(ay.first_date, AccountingMonth.new(y, 9).first_date)
      assert_equal(ay.last_date, AccountingMonth.new(y, 8).last_date)
    end
  end
  
  def test_acc_years_consistent_with_weeks
    for y in 2013..2028 do
      ay = AccountingYear.new(y)
      assert_equal(ay.first_date, Week.new(y, 1).first_date)
    end
  end
end
