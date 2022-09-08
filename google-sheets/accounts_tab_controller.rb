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
  TOTAL_SALES_ROW = 10
  FULL_PRICE_SALES_ROW =11
  MEMBER_SALES_ROW = 12
  STUDENT_SALES_ROW = 13
  OTHER_SALES_ROW = 14
  TOTAL_HIRE_FEES_ROW = 16
  CREDIT_CARD_TAKINGS_ROW = 18


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
    set_title(TOTAL_SALES_ROW, "Ticket Sales")
    set_title(FULL_PRICE_SALES_ROW, "Full Price")
    set_title(MEMBER_SALES_ROW, "Members")
    set_title(STUDENT_SALES_ROW, "Students")
    set_title(OTHER_SALES_ROW, "Other")
    set_title(TOTAL_HIRE_FEES_ROW, "Hire Fees")
    set_title(CREDIT_CARD_TAKINGS_ROW, "Credit card takings")

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
    set_week_values(TOTAL_SALES_ROW, :total_ticket_sales)
    set_week_values(FULL_PRICE_SALES_ROW, :total_full_price_sales)
    set_week_values(MEMBER_SALES_ROW, :total_member_sales)
    set_week_values(STUDENT_SALES_ROW, :total_student_sales)
    set_week_values(OTHER_SALES_ROW, :total_other_ticket_sales)

    set_mtd_value(TOTAL_SALES_ROW)
    def set_vat_value(i_row)
      mtd_cell = @sheet_range[i_row, 1 + @num_weeks]
      vat_value_cell = @sheet_range[i_row, 2 + @num_weeks]
      @wb_controller.set_data(vat_value_cell, "=#{mtd_cell.cell_reference} * #{@vat_cell.cell_reference} / (1 + #{@vat_cell.cell_reference})")
    end
    set_vat_value(TOTAL_SALES_ROW)

    set_week_values(TOTAL_HIRE_FEES_ROW, :total_hire_fee)
    set_vat_value(TOTAL_HIRE_FEES_ROW)
    set_week_values(CREDIT_CARD_TAKINGS_ROW, :total_zettle_reading)
    set_vat_value(CREDIT_CARD_TAKINGS_ROW)

    requests = delete_all_group_rows_requests()
    requests += [
      merge_columns_request(@sheet_range[WEEK_HEADINGS_ROW_1, 1..@num_weeks]),
      set_column_width_request(0, 20),
      set_column_width_request(1, 150),
      set_date_format_request(@sheet_range[MONTH_ROW, 1], "mmm-yy"),
      set_date_format_request(@sheet_range[START_DATE_ROW, 1], "d Mmm yy"),
      set_percentage_format_request(@vat_cell),
      center_text_request(@sheet_range[WEEK_HEADINGS_ROW_1..WEEK_HEADINGS_ROW_2, 1..@num_weeks]),
      group_rows_request(FULL_PRICE_SALES_ROW, OTHER_SALES_ROW),
      set_decimal_format_request(
        @sheet_range[TOTAL_SALES_ROW..OTHER_SALES_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),
      set_decimal_format_request(
        @sheet_range[TOTAL_HIRE_FEES_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),
      set_decimal_format_request(
        @sheet_range[CREDIT_CARD_TAKINGS_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),
    ]

    @wb_controller.apply_requests(requests)




  end
end
