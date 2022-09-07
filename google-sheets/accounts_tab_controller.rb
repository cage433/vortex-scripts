require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

#noinspection RubyDefParenthesesInspection
class AccountsTabController < TabController
  TITLES_COL = 0
  VALUES_COL = 1
  MONTH_ROW = 1
  START_DATE_ROW = 2
  VAT_ROW = 3
  WEEK_HEADINGS_ROW_1 = 6
  WEEK_HEADINGS_ROW_2 = 7
  AUDIENCE_NUMBER_ROW = 8
  ADVANCE_SALES_ROW =10
  CREDIT_CARD_SALES_ROW = 11
  CASH_SALES_ROW = 12
  TOTAL_SALES_ROW = 13
  TOTAL_HIRE_FEES_ROW = 15
  ZETTLE_READING_ROW = 17


  def initialize(month, wb_controller, contracts_and_events, vat_rate)
    super(wb_controller, month.tab_name)
    @month_contracts_and_events = contracts_and_events
    @month = month
    @num_weeks = month.weeks.length
    @width = 1 + @num_weeks + 2

    @sheet_range = SheetRange.new(
      SheetCell.from_coordinates("B1"),
      100,
      @width,
      @sheet_id, @tab_name
    )
    @vat_rate = vat_rate
  end

  def draw()

    clear_values_and_formats()

    def set_title(i_row, title, i_col = 0)
      @wb_controller.set_data(@sheet_range[i_row, i_col], title)
    end
    set_title(MONTH_ROW, "Month")
    set_title(START_DATE_ROW, "Start Date")
    set_title(VAT_ROW, "VAT Rate")
    set_title(AUDIENCE_NUMBER_ROW, "Audience Number")
    set_title(ADVANCE_SALES_ROW, "Advance Sales")
    set_title(CREDIT_CARD_SALES_ROW, "Credit Card Sales")
    set_title(CASH_SALES_ROW, "Cash Sales")
    set_title(TOTAL_SALES_ROW, "Total Sales")
    set_title(TOTAL_HIRE_FEES_ROW, "Total Hire Fees")
    set_title(ZETTLE_READING_ROW, "Zettle Reading")

    @wb_controller.set_data(@sheet_range[MONTH_ROW, 1], @month.first_date)
    @wb_controller.set_data(@sheet_range[START_DATE_ROW, 1], @month.first_week.first_date)
    @vat_cell = @sheet_range[VAT_ROW, 1]
    @wb_controller.set_data(@vat_cell, @vat_rate)


    @wb_controller.set_data(@sheet_range[WEEK_HEADINGS_ROW_1, 1], "Week")
    @wb_controller.set_data(
      @sheet_range[WEEK_HEADINGS_ROW_2, 1..@num_weeks],
      @month.weeks.collect { |w| w.week_number })
    @wb_controller.set_data(@sheet_range[WEEK_HEADINGS_ROW_2, (1 + @num_weeks)], "MTD")
    @wb_controller.set_data(@sheet_range[WEEK_HEADINGS_ROW_2, (2 + @num_weeks)], "VAT estimate")

    def set_mtd_value(i_row)
      range = @sheet_range[i_row, 1..@num_weeks]
      mtd_cell = @sheet_range[i_row, @num_weeks + 1]
      @wb_controller.set_data(mtd_cell, "=SUM(#{range.range_reference})")

    end
    def set_week_values(i_row, sym)
      week_cs_and_es = @month.weeks.collect { |w|
        @month_contracts_and_events.restrict_to_period(w)
      }
      range = @sheet_range[i_row, 1..@num_weeks]
      values = week_cs_and_es.collect { |w| w.method(sym).call() }
      @wb_controller.set_data(range, values)
      set_mtd_value(i_row)
    end
    set_week_values(AUDIENCE_NUMBER_ROW, :total_ticket_count)
    set_week_values(ADVANCE_SALES_ROW, :total_standard_ticket_value)
    set_week_values(CREDIT_CARD_SALES_ROW, :total_member_ticket_value)
    set_week_values(CASH_SALES_ROW, :total_student_ticket_value)

    (1..@num_weeks).each do |i|
      @wb_controller.set_data(
        @sheet_range[TOTAL_SALES_ROW, i],
        "=SUM(#{@sheet_range[ADVANCE_SALES_ROW..CASH_SALES_ROW, i].range_reference})"
      )
    end

    set_mtd_value(TOTAL_SALES_ROW)
    def set_vat_value(i_row)
      mtd_cell = @sheet_range[i_row, 1 + @num_weeks]
      vat_value_cell = @sheet_range[i_row, 2 + @num_weeks]
      @wb_controller.set_data(vat_value_cell, "=#{mtd_cell.cell_reference} * #{@vat_cell.cell_reference} / (1 + #{@vat_cell.cell_reference})")
    end
    set_vat_value(TOTAL_SALES_ROW)

    set_week_values(TOTAL_HIRE_FEES_ROW, :total_hire_fee)
    set_vat_value(TOTAL_HIRE_FEES_ROW)
    set_week_values(ZETTLE_READING_ROW, :total_zettle_reading)
    # @wb_controller.set_data(@sheet_range.row(17),
    #                         ["Total Hire Fees"] +
    #                           week_cs_and_es.collect {|w| w.total_hire_fee } +
    #                           [@month_contracts_and_events.total_hire_fee,""])
    #
    # @wb_controller.set_data(@sheet_range.row(19),
    #                         ["Zettle Reading"] +
    #                           week_cs_and_es.collect {|w| w.total_zettle_reading } +
    #                           [@month_contracts_and_events.total_zettle_reading,""])

    requests = delete_all_group_rows_requests()
    requests += [
      merge_columns_request(@sheet_range[WEEK_HEADINGS_ROW_1, 1..@num_weeks]),
      set_column_width_request(0, 20),
      set_column_width_request(1, 150),
      set_date_format_request(@sheet_range[MONTH_ROW, 1], "mmm-yy"),
      set_date_format_request(@sheet_range[START_DATE_ROW, 1], "d Mmm yy"),
      set_percentage_format_request(@vat_cell),
      center_text_request(@sheet_range[WEEK_HEADINGS_ROW_1..WEEK_HEADINGS_ROW_2, 1..@num_weeks]),
      group_rows_request(12, 14),
      set_decimal_format_request(
        @sheet_range[ADVANCE_SALES_ROW..TOTAL_SALES_ROW, 1..(@num_weeks + 2)],
        "#,###.00"
      )
    ]

    @wb_controller.apply_requests(requests)




  end
end
