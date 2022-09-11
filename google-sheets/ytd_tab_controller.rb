require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

#noinspection RubyDefParenthesesInspection
class YTDAccountsTabController < TabController

  def initialize(year, wb_controller, contracts_and_events)
    super(wb_controller, year.tab_name)
    @contracts_and_events = contracts_and_events
    @year = year
  end

  def draw()
    clear_values_and_formats()
  end
end
