require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'
require_relative '../ledger/ledger'

#noinspection RubyDefParenthesesInspection
class AccountsTabController < TabController
  MONTH_ROW = 1
  START_DATE_ROW = 2
  VAT_ROW = 3

  AUDIENCE_HEADING_ROW = 5
  AUDIENCE_WEEK_ROW, AUDIENCE_ROW, FULL_PRICE_ROW, MEMBER_ROW, STUDENTS_ROW, OTHERS_ROW, GUESTS_ROW = ((AUDIENCE_HEADING_ROW + 2)..(AUDIENCE_HEADING_ROW + 8)).to_a


  INCOMING_HEADING_ROW = 15
  INCOMING_WEEKS_ROW,
    TICKET_SALES_ROW,
    FULL_PRICE_SALES_ROW, MEMBER_SALES_ROW, STUDENT_SALES_ROW,
    OTHER_SALES_ROW,
    TOTAL_HIRE_FEES_ROW, CREDIT_CARD_TAKINGS_ROW, TOTAL_INCOME_ROW = ((INCOMING_HEADING_ROW + 2)..(INCOMING_HEADING_ROW + 10)).to_a

  OUTGOINGS_HEADING_ROW = 27

  OUTGOING_WEEK_ROW, TOTAL_MUSICIAN_COSTS_ROW, MUSICIANS_FEE_ROW,
    ACCOMMODATION_ROW, TRAVEL_EXPENSES_ROW, CATERING_EXPENSES_ROW,
    SOUND_ENGINEERING_ROW,
    PRS_ROW, EVENING_PURCHASES_ROW, TOTAL_OUTGOINGS_ROW = ((OUTGOINGS_HEADING_ROW + 2)..(OUTGOINGS_HEADING_ROW + 11)).to_a

  NET_HEADING_ROW = 40
  NET_WEEK_ROW, NET_TOTAL_ROW = ((NET_HEADING_ROW + 2)..(NET_HEADING_ROW + 3)).to_a

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
      @wb_controller.set_data(@sheet_range.cell(INCOMING_HEADING_ROW, 0), "Incoming")
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
      ledger = Ledger.from_latest_dump
      @wb_controller.set_data(@sheet_range.cell(OUTGOINGS_HEADING_ROW, 0), "Outgoing")
      @wb_controller.set_data(@sheet_range[OUTGOING_WEEK_ROW, 0..(@num_weeks + 2)], ["Week"] + @month.weeks.collect { |w| w.week_number } + ["MTD", "VAT estimate"])
      values = @month.weeks.collect { |w|
        c_and_e = @month_contracts_and_events.restrict_to_period(w)
        [
          c_and_e.total_musician_costs,
          c_and_e.total_musicians_fees,
          c_and_e.total_accommodation_costs,
          c_and_e.total_travel_expenses,
          c_and_e.total_food_budget,
          ledger.sound_engineering_payments(w),
          c_and_e.total_prs_fee,
          c_and_e.total_evening_purchases,
        ]
      }
      values.unshift(
        ["Musician Costs", "Fees", "Accommodation", "Travel", "Catering", "Sound Engineers", "PRS", "Evening Purchases"]
      )
      set_week_values_and_mtd(values.transpose, TOTAL_MUSICIAN_COSTS_ROW..EVENING_PURCHASES_ROW)
    end


    def set_total_outgoings()
      values = (1..(@num_weeks + 2)).collect { |i|
        cell_references = [TOTAL_MUSICIAN_COSTS_ROW, SOUND_ENGINEERING_ROW, PRS_ROW, EVENING_PURCHASES_ROW].collect { |row|
          @sheet_range[row, i].cell_reference
        }
        text = cell_references.join(", ")
        "=SUM(#{text})"
      }
      values.unshift("Total")
      @wb_controller.set_data(@sheet_range[TOTAL_OUTGOINGS_ROW, 0..(@num_weeks + 2)], values)
    end

    def set_net_values()
      @wb_controller.set_data(@sheet_range.cell(NET_HEADING_ROW, 0), "Incoming - Outgoing")
      @wb_controller.set_data(@sheet_range[NET_WEEK_ROW, 0..(@num_weeks + 2)], ["Week"] + @month.weeks.collect { |w| w.week_number } + ["MTD", "VAT estimate"])
      values = (1..(@num_weeks + 1)).collect { |i|
        total_incomes_cell = @sheet_range[TOTAL_INCOME_ROW, i]
        total_outgoings_cell = @sheet_range[TOTAL_OUTGOINGS_ROW, i]
        "=#{total_incomes_cell.cell_reference} - #{total_outgoings_cell.cell_reference}"
      }
      values.unshift("Net")
      @wb_controller.set_data(@sheet_range[NET_TOTAL_ROW, 0..(@num_weeks + 1)], values)
    end

    def set_net_vat()
      net_incoming_vat_cell = @sheet_range[TOTAL_INCOME_ROW, @num_weeks + 2]
      net_outgoing_vat_cell = @sheet_range[TOTAL_OUTGOINGS_ROW, @num_weeks + 2]
      value = "=#{net_incoming_vat_cell.cell_reference} - #{net_outgoing_vat_cell.cell_reference}"
      @wb_controller.set_data(@sheet_range[NET_TOTAL_ROW, @num_weeks + 2], value)
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
    set_net_values()
    set_net_vat()



    def common_formats(range)
      [
        merge_columns_request(range.row(0)),
        center_text_request(range.row(0)),
        set_outside_border_request(range),
        bold_text_request(range.row(0)),
        bold_text_request(range.row(2)),
        bold_text_request(range.row(-1)),
        set_right_border_request(range.column(0).rows(2..)),
        right_align_text_request(range[2, 1 + @num_weeks..]),
      ]

    end
    requests = delete_all_group_rows_requests()
    requests += common_formats(@sheet_range[AUDIENCE_HEADING_ROW..GUESTS_ROW, 0..(@num_weeks + 1)])
    requests += common_formats(@sheet_range[INCOMING_HEADING_ROW..TOTAL_INCOME_ROW, 0..(@num_weeks + 2)])
    requests += common_formats(@sheet_range[OUTGOINGS_HEADING_ROW..TOTAL_OUTGOINGS_ROW, 0..(@num_weeks + 2)])
    requests += common_formats(@sheet_range[NET_HEADING_ROW..NET_TOTAL_ROW, 0..(@num_weeks + 2)])
    requests += [
      set_column_width_request(0, 20),
      set_column_width_request(1, 150),
      set_date_format_request(@sheet_range[MONTH_ROW, 1], "mmm-yy"),
      set_date_format_request(@sheet_range[START_DATE_ROW, 1], "d Mmm yy"),
      set_percentage_format_request(@vat_cell),
      set_outside_border_request(@sheet_range[MONTH_ROW..VAT_ROW, 0..1]),
      bold_text_request(@sheet_range[MONTH_ROW..VAT_ROW, 0]),

      set_top_border_request(@sheet_range[GUESTS_ROW + 1, 0..(@num_weeks + 1)], style: "SOLID_MEDIUM"),
      bold_text_request(@sheet_range[AUDIENCE_WEEK_ROW..AUDIENCE_ROW, 0..(@num_weeks + 1)]),
      set_bottom_border_request(@sheet_range[AUDIENCE_WEEK_ROW, 0..(@num_weeks + 1)]),
      set_right_border_request(@sheet_range[AUDIENCE_WEEK_ROW..GUESTS_ROW, @num_weeks]),
      right_align_text_request(@sheet_range[FULL_PRICE_ROW..GUESTS_ROW, 0]),

      right_align_text_request(@sheet_range[FULL_PRICE_SALES_ROW..OTHER_SALES_ROW, 0]),
      set_bottom_border_request(@sheet_range[INCOMING_WEEKS_ROW, 0..(@num_weeks + 2)]),
      set_bottom_border_request(@sheet_range[CREDIT_CARD_TAKINGS_ROW, 0..(@num_weeks + 2)]),
      set_left_right_border_request(@sheet_range[INCOMING_WEEKS_ROW..TOTAL_INCOME_ROW, 1 + @num_weeks]),
      group_rows_request(FULL_PRICE_SALES_ROW, OTHER_SALES_ROW),
      group_rows_request(FULL_PRICE_ROW, GUESTS_ROW),
      bold_text_request(@sheet_range[TOTAL_INCOME_ROW, 0..(@num_weeks + 2)]),
      bold_text_request(@sheet_range[TICKET_SALES_ROW, 0]),
      bold_text_request(@sheet_range[TOTAL_HIRE_FEES_ROW..CREDIT_CARD_TAKINGS_ROW, 0]),
      set_decimal_format_request(
        @sheet_range[TICKET_SALES_ROW..TOTAL_INCOME_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),

      right_align_text_request(@sheet_range[MUSICIANS_FEE_ROW..CATERING_EXPENSES_ROW, 0]),
      set_bottom_border_request(@sheet_range[OUTGOING_WEEK_ROW, 0..(@num_weeks + 2)]),
      set_bottom_border_request(@sheet_range[EVENING_PURCHASES_ROW, 0..(@num_weeks + 2)]),
      set_right_border_request(@sheet_range[OUTGOING_WEEK_ROW..TOTAL_OUTGOINGS_ROW, 0]),
      set_left_right_border_request(@sheet_range[OUTGOING_WEEK_ROW..TOTAL_OUTGOINGS_ROW, 1 + @num_weeks]),
      bold_text_request(@sheet_range[TOTAL_MUSICIAN_COSTS_ROW, 0]),
      bold_text_request(@sheet_range[SOUND_ENGINEERING_ROW..EVENING_PURCHASES_ROW, 0]),
      bold_text_request(@sheet_range[TOTAL_OUTGOINGS_ROW, 0..(@num_weeks + 2)]),
      group_rows_request(MUSICIANS_FEE_ROW, CATERING_EXPENSES_ROW),
      set_decimal_format_request(
        @sheet_range[TOTAL_MUSICIAN_COSTS_ROW..TOTAL_OUTGOINGS_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),

      set_bottom_border_request(@sheet_range[NET_WEEK_ROW, 0..(@num_weeks + 2)]),
      set_left_right_border_request(@sheet_range[NET_WEEK_ROW..NET_TOTAL_ROW, 1 + @num_weeks]),
      bold_text_request(@sheet_range[NET_HEADING_ROW..NET_TOTAL_ROW, 0..(@num_weeks + 2)]),
      set_decimal_format_request(
        @sheet_range[NET_TOTAL_ROW, 1..(@num_weeks + 2)],
        "#,##0.00"
      ),
    ]

    @wb_controller.apply_requests(requests)


  end
end
