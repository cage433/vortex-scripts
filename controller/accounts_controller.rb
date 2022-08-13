require_relative '../google-sheets/accounts_tab_controller'
require_relative '../env.rb'
require_relative '../date_range/date_range.rb'

class AccountsController
  def initialize()
    @controller = WorkbookController.new(ACCOUNTS_SPREADSHEET_ID)
  end

  def month_tab_controller(month)
    tab_name = month.tab_name
    @controller.add_tab(tab_name) if !@controller.has_tab_with_name?(tab_name)
    ac = AccountsTabController.new(month, @controller)
    ac.draw
  end
end

ac = AccountsController.new()
mtc = ac.month_tab_controller(Month.new(2022, 6))