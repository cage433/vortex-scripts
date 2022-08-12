require 'minitest/autorun'
require_relative '../date_range'

class TestDateRange < Minitest::Test
  def test_month_addition
    m0 = Month.new(year_no: 2019, month_no: 12)
    m1 = Month.new(year_no: 2020, month_no: 1)
    m2 = Month.new(year_no: 2020, month_no: 2)
    m3 = Month.new(year_no: 2020, month_no: 3)
    assert_equal(m0, m1 - 1)
    assert_equal(m0, m3 - 3)
    assert_equal(m1, m0 + 1)
    assert_equal(m2, m0 + 2)
    assert_equal(m3, m0 + 3)
  end

  def test_week_contiguity
    w = Week.new(year_no: 2010, week_number: 1)
    1000.times do |i|
      assert_equal(w.last_date, (w + 1).first_date - 1)
      d = w.first_date
      while d <= w.last_date do
        assert_equal(w, Week.containing(d))
        d += 1
      end
      w += 1
    end
  end
end
