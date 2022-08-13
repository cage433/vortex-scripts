require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

#noinspection RubyDefParenthesesInspection
class AccountsTabController < TabController
  def initialize(month, wb_controller, month_contracts_and_events)
    super(wb_controller, month.tab_name)
    @month_contracts_and_events = month_contracts_and_events
    @month = month
    @width = 9

    @sheet_range = SheetRange.new(
      SheetCell.from_coordinates("A1"),
      100,
      @width,
      @sheet_id, @tab_name
    )
  end

  def week_contracts_and_events(week)
    @month_contracts_and_events.restrict_to_period(week)
  end

  def draw()
    month_range = @sheet_range.row(0).columns(1..2)
    @wb_controller.set_data(month_range, ["Month", @month.first_date])

    start_date_range = @sheet_range.row(1).columns(1..2)
    @wb_controller.set_data(start_date_range, ["Start Date", @month.first_week.first_date])

    start_week_range = @sheet_range.row(5).columns(1..2)
    @wb_controller.set_data(start_week_range, ["Start week", "Week #{@month.first_week.week_number}"])

    week_headings_range_1 = @sheet_range.row(7).columns(1..@month.weeks.length)
    @wb_controller.set_data(week_headings_range_1, ["Week"] * @month.weeks.length)

    week_headings_range_2 = @sheet_range.row(8).columns(0..@month.weeks.length + 2)
    @wb_controller.set_data(week_headings_range_2, ["Week"] + @month.weeks.collect { |w| w.week_number } + ["MTD", "VAT estimate"])

    audience_numbers_range = @sheet_range.row(10).columns(0..@month.weeks.length + 1)
    audience_numbers = @month.weeks.collect { |w|
      @month_contracts_and_events.restrict_to_period(w).total_ticket_count
    }
    @wb_controller.set_data(audience_numbers_range,
                            ["Audience Number"] + audience_numbers + [@month_contracts_and_events.total_ticket_count])

    requests = [
      set_date_format_request(month_range.cell(1), "mmm-yy"),
      set_date_format_request(start_date_range.cell(1), "dd/mm/yyyy"),
      set_background_color_request(start_date_range, @@yellow),
      center_text_request(week_headings_range_1),
      center_text_request(week_headings_range_2.columns(1..@month.weeks.length + 1)),

    ]
    requests += delete_all_group_rows_requests()

    @wb_controller.apply_requests(requests)




  end
end
