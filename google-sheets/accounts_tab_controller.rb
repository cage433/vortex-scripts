require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

#noinspection RubyDefParenthesesInspection
class AccountsTabController < TabController
  MONTH_ROW = 1
  START_DATE_ROW = 2
  VAT_ROW = 3


  AUDIENCE_HEADING_ROW = 6
  AUDIENCE_WEEK_ROW, AUDIENCE_ROW, FULL_PRICE_ROW, MEMBER_ROW, STUDENTS_ROW, OTHERS_ROW, GUESTS_ROW = ((AUDIENCE_HEADING_ROW + 2)..(AUDIENCE_HEADING_ROW + 8)).to_a


  INCOMING_HEADING_ROW = 18
  INCOMING_WEEKS_ROW,
    TICKET_SALES_ROW,
    FULL_PRICE_SALES_ROW, MEMBER_SALES_ROW, STUDENT_SALES_ROW,
    OTHER_SALES_ROW,
    TOTAL_HIRE_FEES_ROW, CREDIT_CARD_TAKINGS_ROW, TOTAL_INCOME_ROW = ((INCOMING_HEADING_ROW + 2)..(INCOMING_HEADING_ROW + 10)).to_a

  OUTGOINGS_HEADING_ROW = 30

  OUTGOING_WEEK_ROW, TOTAL_MUSICIAN_COSTS_ROW, MUSICIANS_FEE_ROW,
    ACCOMMODATION_ROW, TRAVEL_EXPENSES_ROW, CATERING_EXPENSES_ROW,
    PRS_ROW, EVENING_PURCHASES_ROW, TOTAL_OUTGOINGS_ROW = ((OUTGOINGS_HEADING_ROW + 2)..(OUTGOINGS_HEADING_ROW + 10)).to_a


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
      @wb_controller.set_data(@sheet_range.cell(AUDIENCE_HEADING_ROW, 0), "Audience")
      @wb_controller.set_data(@sheet_range[AUDIENCE_WEEK_ROW, 0..(@num_weeks + 1)], ["Week"] + @month.weeks.collect { |w| w.week_number } + ["MTD"])
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
        ["Total", "Full Price", "Members", "Students", "Other", "Guests"]
      )
      set_week_values_and_mtd(values.transpose, AUDIENCE_ROW..GUESTS_ROW)
    end
    def set_incomes()
      @wb_controller.set_data(@sheet_range.cell(INCOMING_HEADING_ROW, 0), "Incomings")
      @wb_controller.set_data(@sheet_range[INCOMING_WEEKS_ROW, 0..(@num_weeks + 2)], ["Week"] + @month.weeks.collect { |w| w.week_number } + ["MTD", "VAT estimate"])
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
        ["Ticket Sales", "Full Price", "Members", "Students", "Other", "Hire Fees", "Credit Card Takings"]
      )
      set_week_values_and_mtd(values.transpose, TICKET_SALES_ROW..CREDIT_CARD_TAKINGS_ROW)
    end

    def set_total_incomes()
      values = (1..(@num_weeks + 1)).collect { |i|
        ticket_sales_cell = @sheet_range[TICKET_SALES_ROW, i]
        hire_fees_cell = @sheet_range[TOTAL_HIRE_FEES_ROW, i]
        credit_card_takings_cell = @sheet_range[CREDIT_CARD_TAKINGS_ROW, i]
        "=SUM(#{ticket_sales_cell.cell_reference}, #{hire_fees_cell.cell_reference}, #{credit_card_takings_cell.cell_reference})"
      }
      values.unshift("Total")
      @wb_controller.set_data(@sheet_range[TOTAL_INCOME_ROW, 0..(@num_weeks + 1)], values)

    end
    def set_outgoings()
      @wb_controller.set_data(@sheet_range.cell(OUTGOINGS_HEADING_ROW, 0), "Outgoings")
      @wb_controller.set_data(@sheet_range[OUTGOING_WEEK_ROW, 0..(@num_weeks + 2)], ["Week"] + @month.weeks.collect { |w| w.week_number } + ["MTD", "VAT estimate"])
      values = @month.weeks.collect { |w|
        c_and_e = @month_contracts_and_events.restrict_to_period(w)
        [
          c_and_e.total_musician_costs,
          c_and_e.total_musicians_fees,
          c_and_e.total_accommodation_costs,
          c_and_e.total_travel_expenses,
          c_and_e.total_food_budget,
          c_and_e.total_prs_fee,
          c_and_e.total_evening_purchases,
        ]
      }
      values.unshift(
        ["Musician Costs", "Fees", "Accommodation", "Travel", "Catering", "PRS", "Evening Purchases"]
      )
      set_week_values_and_mtd(values.transpose, TOTAL_MUSICIAN_COSTS_ROW..EVENING_PURCHASES_ROW)
    end

    # def set_prs()
    #   values = @month.weeks.collect { |w|
    #     @month_contracts_and_events.restrict_to_period(w).total_prs_fee
    #   }.unshift(
    #     "PRS"
    #   )
    #   set_week_values_and_mtd([values], PRS_ROW..PRS_ROW)
    # end
    #
    # def set_evening_purchases()
    #   values = @month.weeks.collect { |w|
    #     @month_contracts_and_events.restrict_to_period(w).total_evening_purchases
    #   }.unshift(
    #     "Evening Purchases"
    #   )
    #   set_week_values_and_mtd([values], EVENING_PURCHASES_ROW..EVENING_PURCHASES_ROW)
    # end


    def set_total_outgoings()
      values = (1..(@num_weeks + 1)).collect { |i|
        musician_costs_cell = @sheet_range[TOTAL_MUSICIAN_COSTS_ROW, i]
        prs_cell = @sheet_range[PRS_ROW, i]
        evening_purchases_cell = @sheet_range[EVENING_PURCHASES_ROW, i]
        "=SUM(#{musician_costs_cell.cell_reference}, #{prs_cell.cell_reference}, #{evening_purchases_cell.cell_reference})"
      }
      values.unshift("Total")
      @wb_controller.set_data(@sheet_range[TOTAL_OUTGOINGS_ROW, 0..(@num_weeks + 1)], values)

    end
    def set_vat_value(i_row)
      mtd_cell = @sheet_range[i_row, 1 + @num_weeks]
      vat_value_cell = @sheet_range[i_row, 2 + @num_weeks]
      @wb_controller.set_data(vat_value_cell, "=#{mtd_cell.cell_reference} * #{@vat_cell.cell_reference} / (1 + #{@vat_cell.cell_reference})")
    end

    set_top_headings()
    set_tickets_sold()
    set_incomes()
    set_vat_value(TICKET_SALES_ROW)
    set_vat_value(TOTAL_HIRE_FEES_ROW)
    set_vat_value(CREDIT_CARD_TAKINGS_ROW)
    set_total_incomes()
    set_vat_value(TOTAL_INCOME_ROW)
    set_outgoings()
    set_total_outgoings()
    set_vat_value(PRS_ROW)






    requests = delete_all_group_rows_requests()
    requests += [
      set_column_width_request(0, 20),
      set_column_width_request(1, 150),
      set_date_format_request(@sheet_range[MONTH_ROW, 1], "mmm-yy"),
      set_date_format_request(@sheet_range[START_DATE_ROW, 1], "d Mmm yy"),
      set_percentage_format_request(@vat_cell),
      set_outside_border_request(@sheet_range[MONTH_ROW..VAT_ROW, 0..1]),
      bold_text_request(@sheet_range[MONTH_ROW..VAT_ROW, 0]),

      merge_columns_request(@sheet_range[AUDIENCE_HEADING_ROW, 0..(1 + @num_weeks)]),
      center_text_request(@sheet_range[AUDIENCE_HEADING_ROW, 0..(1 + @num_weeks)]),
      set_outside_border_request(@sheet_range[AUDIENCE_HEADING_ROW..GUESTS_ROW, 0..(@num_weeks + 1)]),
      set_top_border_request(@sheet_range[GUESTS_ROW + 1, 0..(@num_weeks + 1)], style: "SOLID_MEDIUM"),
      bold_text_request(@sheet_range[AUDIENCE_HEADING_ROW, 0..(@num_weeks + 1)]),
      bold_text_request(@sheet_range[AUDIENCE_WEEK_ROW..AUDIENCE_ROW, 0..(@num_weeks + 1)]),
      set_bottom_border_request(@sheet_range[AUDIENCE_WEEK_ROW, 0..(@num_weeks + 1)]),
      set_right_border_request(@sheet_range[AUDIENCE_WEEK_ROW..GUESTS_ROW, 0]),
      set_right_border_request(@sheet_range[AUDIENCE_WEEK_ROW..GUESTS_ROW, @num_weeks]),
      right_align_text_request(@sheet_range[AUDIENCE_WEEK_ROW, 1 + @num_weeks]),
      right_align_text_request(@sheet_range[FULL_PRICE_ROW..GUESTS_ROW, 0]),

      merge_columns_request(@sheet_range[INCOMING_HEADING_ROW, 0..(2 + @num_weeks)]),
      center_text_request(@sheet_range[INCOMING_HEADING_ROW, 0..(2 + @num_weeks)]),
      right_align_text_request(@sheet_range[FULL_PRICE_SALES_ROW..OTHER_SALES_ROW, 0]),
      right_align_text_request(@sheet_range[INCOMING_WEEKS_ROW, (1 + @num_weeks)..(2 + @num_weeks)]),
      set_outside_border_request(@sheet_range[INCOMING_HEADING_ROW..TOTAL_INCOME_ROW, 0..(@num_weeks + 2)]),
      set_bottom_border_request(@sheet_range[INCOMING_WEEKS_ROW, 0..(@num_weeks + 2)]),
      set_bottom_border_request(@sheet_range[CREDIT_CARD_TAKINGS_ROW, 0..(@num_weeks + 2)]),
      set_right_border_request(@sheet_range[INCOMING_WEEKS_ROW..TOTAL_INCOME_ROW, 0]),
      set_left_right_border_request(@sheet_range[INCOMING_WEEKS_ROW..TOTAL_INCOME_ROW, 1 + @num_weeks]),
      group_rows_request(FULL_PRICE_SALES_ROW, OTHER_SALES_ROW),
      group_rows_request(FULL_PRICE_ROW, GUESTS_ROW),
      bold_text_request(@sheet_range[TOTAL_INCOME_ROW, 0..(@num_weeks + 2)]),
      bold_text_request(@sheet_range[INCOMING_HEADING_ROW..INCOMING_WEEKS_ROW, 0..(@num_weeks + 2)]),
      bold_text_request(@sheet_range[TICKET_SALES_ROW, 0]),
      bold_text_request(@sheet_range[TOTAL_HIRE_FEES_ROW..CREDIT_CARD_TAKINGS_ROW, 0]),
      set_decimal_format_request(
        @sheet_range[TICKET_SALES_ROW..TOTAL_INCOME_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),
      # set_decimal_format_request(
      #   @sheet_range[ACCOMMODATION_ROW, 1..(@num_weeks + 2)],
      #   "#,##0.00"
      # ),



      merge_columns_request(@sheet_range[OUTGOINGS_HEADING_ROW, 0..(2 + @num_weeks)]),
      center_text_request(@sheet_range[OUTGOINGS_HEADING_ROW, 0..(2 + @num_weeks)]),
      right_align_text_request(@sheet_range[MUSICIANS_FEE_ROW..CATERING_EXPENSES_ROW, 0]),
      set_outside_border_request(@sheet_range[OUTGOINGS_HEADING_ROW..TOTAL_OUTGOINGS_ROW, 0..(@num_weeks + 2)]),
      right_align_text_request(@sheet_range[OUTGOING_WEEK_ROW, (1 + @num_weeks)..(2 + @num_weeks)]),
      set_bottom_border_request(@sheet_range[OUTGOING_WEEK_ROW, 0..(@num_weeks + 2)]),
      set_bottom_border_request(@sheet_range[EVENING_PURCHASES_ROW, 0..(@num_weeks + 2)]),
      set_right_border_request(@sheet_range[OUTGOING_WEEK_ROW..TOTAL_OUTGOINGS_ROW, 0]),
      set_left_right_border_request(@sheet_range[OUTGOING_WEEK_ROW..TOTAL_OUTGOINGS_ROW, 1 + @num_weeks]),
      bold_text_request(@sheet_range[OUTGOINGS_HEADING_ROW..OUTGOING_WEEK_ROW, 0..(@num_weeks + 2)]),
      bold_text_request(@sheet_range[TOTAL_OUTGOINGS_ROW, 0..(@num_weeks + 2)]),
      group_rows_request(MUSICIANS_FEE_ROW, CATERING_EXPENSES_ROW),
      set_decimal_format_request(
        @sheet_range[TOTAL_MUSICIAN_COSTS_ROW..TOTAL_OUTGOINGS_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),
    ]

    @wb_controller.apply_requests(requests)




  end
end
