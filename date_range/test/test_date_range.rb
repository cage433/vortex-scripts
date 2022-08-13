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

  def test_week_contiguity
    w = Week.new(2010, 1)
    1000.times do |i|
      assert_equal(w.last_date, (w + 1).first_date - 1)
      d = w.first_date
      while d <= w.last_date do
        if w != Week.containing(d) then
          foo = Week.containing(d)
        end
        assert_equal(w, Week.containing(d))
        d += 1
      end
      w += 1
    end
  end

  def test_weeks_in_month
    m = Month.new(2015, 1)
    50.times do |i|
      assert_equal((m - 1).last_week + 1, m.first_week)
      assert_equal((m + 1).first_week - 1, m.last_week)
      m += 1
    end
  end
end
