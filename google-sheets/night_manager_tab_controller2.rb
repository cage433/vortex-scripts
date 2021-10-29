require_relative 'tab-controller'

class NightManagerTabController2 < TabController
  def initialize(date, wb_controller)
    super(wb_controller, TabController.tab_name_for_date(date))
    @date = date
  end
end
