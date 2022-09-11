require_relative '../google-sheets/ytd_tab_controller'
require_relative '../env.rb'
require_relative '../date_range/date_range.rb'
require_relative '../airtable/contract_and_events'

class YTDAccountsController
  def initialize()
    @controller = WorkbookController.new(YTD_ACCOUNTS_SPREADSHEET_ID)
  end

  def year_tab_controller(year)
    tab_name = year.tab_name
    @controller.add_tab(tab_name) if !@controller.has_tab_with_name?(tab_name)
    ac = YTDAccountsTabController.new(year, @controller, MultipleContractsAndEvents.read_many(date_range: year.vortex_week_range))
    ac.draw()
  end
end

ac = YTDAccountsController.new()
# (5..8).each do |month_no|
#   ac.month_tab_controller(Month.new(2022, month_no))
# end
mtc = ac.year_tab_controller(AccountingYear.new(2022))
