require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

class AccountsTabController < TabController
  def initialize(year_no, month_no, wb_controller)
    super(wb_controller, TabController.tab_name_for_month(year_no, month_no))
    @year_no = year_no
    @month_no = month_no
  end
end
