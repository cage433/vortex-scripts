require_relative '../google-sheets/accounts_tab_controller'
require_relative '../env.rb'

class AccountsController
  def initialize()
    @controller = WorkbookController.new(ACCOUNTS_SPREADSHEET_ID)
  end

  def month_tab_controller(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    @controller.add_tab(tab_name) if !@controller.has_tab_with_name?(tab_name)
    AccountsTabController.new(year, month, @controller)
  end
end

ac = AccountsController.new()
mtc = ac.month_tab_controller(2020, 1)