require_relative '../google-sheets/accounts_tab_controller'
require_relative '../env.rb'
require_relative '../date_range/date_range.rb'
require_relative '../airtable/contract_and_events'

class AccountsController
  def initialize()
    @controller = WorkbookController.new(ACCOUNTS_SPREADSHEET_ID)
  end

  def month_tab_controller(month)
    tab_name = month.tab_name
    @controller.add_tab(tab_name) if !@controller.has_tab_with_name?(tab_name)
    vat_rate = 0.2
    ac = AccountsTabController.new(month, @controller, MultipleContractsAndEvents.read_many(date_range: month), vat_rate)
    ac.draw()
  end
end

ac = AccountsController.new()
# (5..8).each do |month_no|
#   ac.month_tab_controller(Month.new(2022, month_no))
# end
mtc = ac.month_tab_controller(AccountingMonth.new(2022, 8))
