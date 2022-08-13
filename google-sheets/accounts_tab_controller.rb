require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

class AccountsTabController < TabController
  def initialize(month, wb_controller)
    super(wb_controller, month.tab_name)
    @month = month
    @width = 9

    @sheet_range = SheetRange.new(
      SheetCell.from_coordinates("A1"),
      100,
      @width,
      @sheet_id, @tab_name
    )
  end

  def draw

    month_range = @sheet_range.row(0).columns(1..2)
    @wb_controller.set_data(month_range, ["Month", @month.first_date])

    start_date_range = @sheet_range.row(1).columns(1..2)
    @wb_controller.set_data(start_date_range, ["Start Date", @month.first_week.first_date])

    start_week_range = @sheet_range.row(5).columns(1..2)
    @wb_controller.set_data(start_week_range, ["Start week", "Week #{@month.first_week.week_number}"])

    requests = [
      set_date_format_request(month_range.cell(1), "mmm-yy"),
      set_date_format_request(start_date_range.cell(1), "dd/mm/yyyy"),
      set_background_color_request(start_date_range, @@yellow)
    ]

    @wb_controller.apply_requests(requests)



  end
end
