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
  AUDIENCE_NUMBERS_ROW = 8
  FULL_PRICE_NUMBERS_ROW = 9
  MEMBER_NUMBERS_ROW = 10
  STUDENT_NUMBERS_ROW = 11
  OTHER_NUMBERS_ROW = 12
  GUEST_NUMBERS_ROW = 13

  TOTAL_TICKET_SALES_ROW = 15
  FULL_PRICE_SALES_ROW =16
  MEMBER_SALES_ROW = 17
  STUDENT_SALES_ROW = 18
  OTHER_SALES_ROW = 19
  TOTAL_HIRE_FEES_ROW = 20
  CREDIT_CARD_TAKINGS_ROW = 21
  TOTAL_INCOME_ROW = 22

  TOTAL_MUSICIAN_COSTS_ROW = 24
  MUSICIANS_FEE_ROW = 25
  ACCOMMODATION_ROW = 26
  TRAVEL_EXPENSES_ROW = 27
  CATERING_EXPENSES_ROW = 28

  PRS_ROW = 30

  EVENING_PURCHASES_ROW = 32

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

    @vat_cell = @sheet_range[VAT_ROW, 1]

    @wb_controller.set_data(@sheet_range[WEEK_HEADINGS_ROW_1, 1], "Week")
    @wb_controller.set_data(
      @sheet_range[WEEK_HEADINGS_ROW_2, 1..(@num_weeks + 2)],
      @month.weeks.collect { |w| w.week_number } + ["MTD", "VAT estimate"]
    )

    def set_top_headings()
      @wb_controller.set_data(
        @sheet_range[MONTH_ROW..VAT_ROW, 0..1],
        [
          ["Month", @month.first_date],
          ["Start Date", @month.first_week.first_date],
          ["VAT Rate", @vat_rate]
        ]
      )
    end

    def set_week_values_and_mtd(values, row_range)
      values = values.zip(row_range).collect {|row, i|
        range = @sheet_range[i, 1..@num_weeks]
        row.append("=SUM(#{range.range_reference})")
      }
      @wb_controller.set_data(@sheet_range[row_range, 0..(@num_weeks + 1)], values)
    end

    def set_tickets_sold()
      values = @month.weeks.collect { |w|
        c_and_e = @month_contracts_and_events.restrict_to_period(w)
        [
          c_and_e.total_ticket_count,
          c_and_e.total_full_price_tickets,
          c_and_e.total_member_tickets,
          c_and_e.total_student_tickets,
          c_and_e.total_other_tickets,
          c_and_e.total_guest_tickets,
        ]
      }
      values.unshift(
        ["Audience Numbers", "Full Price", "Members", "Students", "Other", "Guests"]
      )
      set_week_values_and_mtd(values.transpose, AUDIENCE_NUMBERS_ROW..GUEST_NUMBERS_ROW)
    end
    def set_incomes()
      values = @month.weeks.collect { |w|
        c_and_e = @month_contracts_and_events.restrict_to_period(w)
        [
          c_and_e.total_ticket_sales,
          c_and_e.total_full_price_sales,
          c_and_e.total_member_sales,
          c_and_e.total_student_sales,
          c_and_e.total_other_ticket_sales,
          c_and_e.total_hire_fee,
          c_and_e.total_zettle_reading,
        ]
      }
      values.unshift(
        ["Ticket Sales", "Full Price", "Members", "Students", "Other", "Hire Fees", "Credit card takings"]
      )
      set_week_values_and_mtd(values.transpose, TOTAL_TICKET_SALES_ROW..CREDIT_CARD_TAKINGS_ROW)
    end

    def set_outgoings()
      values = @month.weeks.collect { |w|
        c_and_e = @month_contracts_and_events.restrict_to_period(w)
        [
          c_and_e.total_musician_costs,
          c_and_e.total_musicians_fees,
          c_and_e.total_accommodation_costs,
          c_and_e.total_travel_expenses,
          c_and_e.total_food_budget
        ]
      }
      values.unshift(
        ["Musician Costs", "Fees", "Accommodation", "Travel", "Catering"]
      )
      set_week_values_and_mtd(values.transpose, TOTAL_MUSICIAN_COSTS_ROW..CATERING_EXPENSES_ROW)
    end

    def set_prs()
      values = @month.weeks.collect { |w|
        @month_contracts_and_events.restrict_to_period(w).total_prs_fee
      }.unshift(
        "PRS"
      )
      set_week_values_and_mtd([values], PRS_ROW..PRS_ROW)
    end

    def set_evening_purchases()
      values = @month.weeks.collect { |w|
        @month_contracts_and_events.restrict_to_period(w).total_evening_purchases
      }.unshift(
        "Evening Purchases"
      )
      set_week_values_and_mtd([values], EVENING_PURCHASES_ROW..EVENING_PURCHASES_ROW)
    end

    set_top_headings()
    set_tickets_sold()
    set_incomes()
    set_outgoings()
    set_prs()
    set_evening_purchases()


    def set_vat_value(i_row)
      mtd_cell = @sheet_range[i_row, 1 + @num_weeks]
      vat_value_cell = @sheet_range[i_row, 2 + @num_weeks]
      @wb_controller.set_data(vat_value_cell, "=#{mtd_cell.cell_reference} * #{@vat_cell.cell_reference} / (1 + #{@vat_cell.cell_reference})")
    end
    set_vat_value(TOTAL_TICKET_SALES_ROW)

    set_vat_value(TOTAL_HIRE_FEES_ROW)
    set_vat_value(CREDIT_CARD_TAKINGS_ROW)

    def set_total_incomes()
      values = (1..(@num_weeks + 1)).collect { |i|
        ticket_sales_cell = @sheet_range[TOTAL_TICKET_SALES_ROW, i]
        hire_fees_cell = @sheet_range[TOTAL_HIRE_FEES_ROW, i]
        credit_card_takings_cell = @sheet_range[CREDIT_CARD_TAKINGS_ROW, i]
        "=SUM(#{ticket_sales_cell.cell_reference}, #{hire_fees_cell.cell_reference}, #{credit_card_takings_cell.cell_reference})"
      }
      values.unshift("Total Income")
      @wb_controller.set_data(@sheet_range[TOTAL_INCOME_ROW, 0..(@num_weeks + 1)], values)

    end

    set_total_incomes()
    set_vat_value(TOTAL_INCOME_ROW)

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
      group_rows_request(FULL_PRICE_NUMBERS_ROW, GUEST_NUMBERS_ROW),
      group_rows_request(MUSICIANS_FEE_ROW, CATERING_EXPENSES_ROW),
    ]
    (TOTAL_TICKET_SALES_ROW..TOTAL_INCOME_ROW).to_a + [
      TOTAL_TICKET_SALES_ROW, TOTAL_HIRE_FEES_ROW, CREDIT_CARD_TAKINGS_ROW, TOTAL_INCOME_ROW,
      MUSICIANS_FEE_ROW, ACCOMMODATION_ROW
    ].each { |i|
      requests.append(
        set_decimal_format_request(
          @sheet_range[i, 1..(@num_weeks + 2)],
          "#,##0.00"
        )
      )
    }

    @wb_controller.apply_requests(requests)




  end
end
