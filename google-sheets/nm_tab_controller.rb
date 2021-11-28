require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

class ExpensesRange < TabController
  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
    @expenses_list_range = @range.rows(2..)
  end

  def initialise_range()
    @wb_controller.set_data(
      @range.cell(0, 0),
      "Expenses"
    )
    @wb_controller.set_data(
      @range.cell(1, 0),
      "Note"
    )
    @wb_controller.set_data(
      @range.cell(1, 4),
      "Amount (£)"
    )
    requests = [
      bold_and_center_request(@range.rows(0..1)),
      set_outside_border_request(@range),
      set_border_request(@range.row(1), style: "SOLID", borders: [:bottom]),
      set_border_request(@range.column(3).rows(1..), style: "SOLID", borders: [:right]),
      merge_columns_request(@range.row(0)),
      set_background_color_request(@expenses_list_range, @@almond),
      set_currency_format_request(@range.column(-1).rows(2..)),
    ]
    (1...@range.num_rows).each { |i_row|
      requests.push(merge_columns_request(@range.row(i_row).columns(0..3)))
    }
    @wb_controller.apply_requests(requests)
  end

  def read_expenses()
    expenses_data = get_spreadsheet_values(@expenses_list_range) || []
    expenses = []
    expenses_data.each { |data_row|
      note = data_row[0]
      amount = data_row[-1]
      if !note.nil? && note.strip != ""
        expenses.push(NMForm_ExpensesData.new(note: note, amount: amount))
      end
    }
    expenses
  end

  def write_expenses(expenses_data)
    assert_collection_type(expenses_data, NMForm_ExpensesData)
    clear_values(@expenses_list_range)
    notes = expenses_data.collect{ |e| e.note}
    amounts = expenses_data.collect{ |e| e.amount}
    if notes.size > 0
      @wb_controller.set_data(
        @expenses_list_range.column(0).rows(...(notes.length)),
        notes
      )
      @wb_controller.set_data(
        @expenses_list_range.column(4).rows(...(amounts.length)),
        amounts
      )
    end
  end
end

class TicketSalesRange < TabController
  attr_reader :total_ticket_sales

  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
    @row_titles = @range.columns(0..1)
    @total_ticket_sales = @range.cell(-1, -1)
    sales_cols = @range.columns(2..3)
    @online_range = sales_cols.rows(4..5)
    @walk_in_range = sales_cols.rows(8..9)
    @guest_cheap_range = sales_cols.rows(12..13)
  end

  def initialise_range()
    @wb_controller.set_data(
      @row_titles,
      [
        ["Takings", ""],
        ["", ""],
        ["", ""],
        ["Online", ""],
        ["", "Tickets"],
        ["", "Total Paid (£)"],
        ["", ""],
        ["Walk-ins", ""],
        ["", "Num"],
        ["", "Total Paid (£)"],
        ["", ""],
        ["Guests/Cheap", ""],
        ["", "Num"],
        ["", "Total Paid (£)"],
        ["", ""],
        ["Totals", ""],
        ["", "Audience"],
        ["", "Total Paid (£)"],
      ]
    )
    @wb_controller.set_data(
      @range.row(1), 
      ["", "", "Gig 1", "Gig 2", "Total"]
    )

    [4, 5, 8, 9, 12, 13, 16, 17].each do |i_row|
      row = @range.row(i_row)
      sum_refs = [2, 3].collect{ |i_col| row.cell(i_col).cell_reference()}.join("+")
      
      @wb_controller.set_data( row.cell(4), "=#{sum_refs}" 
      )
    end
    [2, 3].each do |i_col|
      col = @range.column(i_col)

      sum_ticket_refs = [4, 8, 12].collect{ |i_row| col.cell(i_row).cell_reference()}.join("+")
      @wb_controller.set_data( col.cell(16), "=#{sum_ticket_refs}" )

      sum_amount_refs = [5, 9, 13].collect{ |i_row| col.cell(i_row).cell_reference()}.join("+")
      @wb_controller.set_data( col.cell(17), "=#{sum_amount_refs}" )
    end

    requests = [
      set_outside_border_request(@range),
      text_format_request(@row_titles, {bold: true}),
      text_format_request(@range.rows(0..1), {bold: true}),
      set_top_bottom_border_request(@range.rows(2..5)),
      set_top_bottom_border_request(@range.rows(10..13)),
      set_left_right_border_request(@range.rows(1..).columns(2..3)),
      merge_columns_request(@range.row(0)),
      center_text_request(@range.rows(0..1)),
    ]
    [4, 8, 12].each do |i_row|
      requests.push(
        set_background_color_request(
          @range.rows(i_row..i_row+1).columns(2..3), 
          @@almond
        )
      )
    end
    [5, 9, 13].each do |i_row|
      requests.push(
        set_currency_format_request(@range.row(i_row).columns(2..4))
      )
    end

    @wb_controller.apply_requests(requests)
  end

  def read_ticket_sales()
    def number_and_value(tickets_and_paid_range, i_col)
      NumberSoldAndValue.new(
        number: get_cell_value(tickets_and_paid_range.cell(0, i_col)), 
        value: get_cell_value(tickets_and_paid_range.cell(1, i_col))
      )
    end
    def ticket_sales_for_gig(i_col)
      NMFormTicketSales.new(
        gig: "Gig #{i_col + 1}",
        online: number_and_value(@online_range, i_col),
        walk_ins: number_and_value(@walk_in_range, i_col),
        guests_and_cheap: number_and_value(@guest_cheap_range, i_col),
      )
    end
    (0..1).collect{ |i_gig| ticket_sales_for_gig(i_gig) }
  end

  def write_ticket_sales(ticket_sales)
    assert_collection_type(ticket_sales, NMFormTicketSales)
    def set_number_and_value(tickets_and_paid_range, i_col, number_and_value)
      @wb_controller.set_data(
        tickets_and_paid_range.column(i_col),
        [number_and_value.number, number_and_value.value]
      )
    end
    ticket_sales.each do |ts| 
      i_col = ts.gig_number - 1
      set_number_and_value(@online_range, i_col, ts.online)
      set_number_and_value(@walk_in_range, i_col, ts.walk_ins)
      set_number_and_value(@guest_cheap_range, i_col, ts.guests_and_cheap)
    end
  end
end

class NotesRange < TabController
  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
    @header = @range.row(0)
    @notes_range = @range.rows(1..)
  end

  def initialise_range()
    @wb_controller.set_data(
      @header.cell(0), 
      "Notes"
    )
    requests = [
      set_outside_border_request(@range),
      set_border_request(@header, style: "SOLID", borders: [:bottom]),
      set_background_color_request(@notes_range, @@almond),
      bold_and_center_request(@header),
    ]
    (0...@range.num_rows).each { |i_row|
      requests.push(merge_columns_request(@range.row(i_row)))
    }
    @wb_controller.apply_requests(requests)
  end

  def write_merged_note(merged_note)
    lines = merged_note.split("\n")
    lines_to_write = lines[...(@notes_range.num_rows)]
    @wb_controller.set_data(
      @notes_range.column(0).rows(...(lines_to_write.size)),
      lines_to_write
    )
  end

  def read_merged_note()
    notes = (get_spreadsheet_values(@notes_range) || []).collect{ |row| row[0]}.filter { |note| !note.nil? && note.strip != ""}
    if notes.size > 0 then notes.join("\n") else nil end
  end
end

class HeadingsRange < TabController
  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
    @date_cell = @range.cell(0, 1)
    @title_cell = @range.cell(1, 1)
  end

  def initialise_range(date, title)
    @wb_controller.set_data(@range.columns(0..1), [["Date", date], ["Title", title]])
    requests = [
      set_date_format_request(@date_cell, "d mmm yy"),
      right_align_text_request(@title_cell),
      text_format_request(@range, {bold: true, font_size: 14}),
      set_outside_border_request(@range),
      merge_columns_request(@range.row(0).columns(1..4)),
      merge_columns_request(@range.row(1).columns(1..4)),
    ]

    @wb_controller.apply_requests(requests)
  end

end

class FeeDetailsRange < TabController
  def initialize(wb_controller, range, tab_name, ticket_sales_range, fee_details)
    super(wb_controller, tab_name)
    @range = range
    @fee_to_pay_cell = @range.cell(5, 1)
    @ticket_sales_range = ticket_sales_range
    @fee_details = fee_details
  end

  def initialise_range()
    flat_fee_cell, split_cell, ticket_sales_cell = (2..4).collect{ |i_row| @range.cell(i_row, 1)}
    @wb_controller.set_data(
      @range.column(0),
      [
        "Band Fee",
        "",
        "Flat Fee",
        "Split",
        "Ticket Sales",
        "Fee to pay"
      ]
    )
    @wb_controller.set_data(flat_fee_cell, @fee_details.flat_fee)
    @wb_controller.set_data(split_cell, @fee_details.percentage_split)
    @wb_controller.set_data(
      ticket_sales_cell, 
      "=#{@ticket_sales_range.total_ticket_sales.cell_reference}"
    )
    @wb_controller.set_data(
      @fee_to_pay_cell, 
      if @fee_details.vs_fee 
        "=max(#{flat_fee_cell.cell_reference}, #{split_cell.cell_reference} * #{@ticket_sales_range.total_ticket_sales.cell_reference})"
      else
        "=#{flat_fee_cell.cell_reference} + #{split_cell.cell_reference} * #{@ticket_sales_range.total_ticket_sales.cell_reference}"
      end
    )

    requests = [
      set_outside_border_request(@range),
      set_border_request(@range.row(0), style: "SOLID", borders: [:bottom]),
      merge_columns_request(@range.row(0)),
      bold_text_request(@range.column(0)),
      bold_and_center_request(@range.row(0)),
      set_currency_format_request(flat_fee_cell),
      set_percentage_format_request(split_cell),
      set_currency_format_request(@fee_to_pay_cell),
    ]
    @wb_controller.apply_requests(requests)
  end

  def fee_to_pay_value
    get_cell_value(@fee_to_pay_cell) || 0.0
  end
  
end

class PRSRange < TabController
  def initialize(wb_controller, range, tab_name, ticket_sales_range)
    super(wb_controller, tab_name)
    @range = range
    @fully_improvised_cell = @range.cell(2, 1)
    @prs_to_pay_cell = @range.cell(3, 1)
    @ticket_sales_range = ticket_sales_range
  end

  def initialise_range()
    @wb_controller.set_data(
      @range.column(0),
      ["PRS", "", "Fully Improvised", "To Pay"]
    )
    @wb_controller.set_data(
      @prs_to_pay_cell,
      "=if(#{@fully_improvised_cell.cell_reference}, 0.0, 0.04 * #{@ticket_sales_range.total_ticket_sales.cell_reference})"
    )
    requests = [
      set_outside_border_request(@range),
      set_border_request(@range.row(0), style: "SOLID", borders: [:bottom]),
      merge_columns_request(@range.row(0)),
      bold_text_request(@range.column(0)),
      bold_and_center_request(@range.row(0)),
      create_checkbox_request(@fully_improvised_cell),
      set_currency_format_request(@prs_to_pay_cell),
      set_background_color_request(@fully_improvised_cell, @@almond),
    ]
    @wb_controller.apply_requests(requests)
  end

  def set_fully_improvised(fully_improvised)
    @wb_controller.set_data(
      @fully_improvised_cell, fully_improvised
    )
  end

  def fully_improvised()
    get_cell_value(@fully_improvised_cell)
  end

  def prs_to_pay_value()
    get_cell_value(@prs_to_pay_cell)
  end
end

class ZReadingsRange < TabController
  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
    @header = @range.row(0)
    @readings_range = @range.column(1).rows(2..)
    @cash_reading_cell = @readings_range.cell(0)
    @zettle_reading_cell = @readings_range.cell(1)
  end

  def initialise_range()
    @wb_controller.set_data(
      @range.column(0),
      ["Z Readings", "", "Cash (£)", "Zettle (£)"]
    )
    amounts_range = @range.rows(2..3).column(1)
    requests = [
      set_outside_border_request(@range),
      set_border_request(@header, style: "SOLID", borders: [:bottom]),
      merge_columns_request(@header),
      bold_and_center_request(@range.column(0)),
      set_currency_format_request(@readings_range),
      set_background_color_request(@readings_range, @@almond),
    ]
    @wb_controller.apply_requests(requests)
  end

  def zettle_reading_value()
    get_cell_value(@zettle_reading_cell)
  end

  def cash_reading_value()
    get_cell_value(@cash_reading_cell)
  end

  def set_z_readings(session_data)
    @wb_controller.set_data(
      @readings_range,
      [session_data.cash_z_reading, session_data.zettle_z_reading]
    )
  end
end

class MerchRange < TabController
  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
    @input_range = @range.rows(2..).columns(1..)
  end

  def initialise_range()
    @wb_controller.set_data(
      @range.column(0).rows(2..5),
      ["Mugs", "T-shirts", "Bags", "Masks"]
    )
    @wb_controller.set_data(
      @range.row(1).columns(1..2),
      ["Number", "Amount (£)"]
    )
    titles_range = @range.rows(0..1)
    requests = [
      set_outside_border_request(@range),
      set_border_request(@range.row(1), style: "SOLID", borders: [:bottom]),
      set_border_request(@range.column(0).rows(1..), style: "SOLID", borders: [:right]),
      merge_columns_request(@range.row(0)),
      bold_and_center_request(titles_range),
      bold_text_request(@range.column(0)),
      set_background_color_request(@input_range, @@almond),
      set_currency_format_request(@input_range.column(1)),
    ]
    @wb_controller.apply_requests(requests)

  end

  def number_and_value(i_row)
    row = @input_range.row(i_row)
    NumberSoldAndValue.new(
      number: get_cell_value(row.cell(0)), 
      value: get_cell_value(row.cell(1))
    )
  end

  def mugs_number_and_value()
    number_and_value(0)
  end

  def t_shirts_number_and_value()
    number_and_value(1)
  end

  def bags_number_and_value()
    number_and_value(2)
  end

  def masks_number_and_value()
    number_and_value(3)
  end

  def set_merch_data(session_data)
    data = [session_data.mugs, session_data.t_shirts, session_data.bags, session_data.masks].collect { |item|
      [item.number, item.value]
    }
    @wb_controller.set_data(
      @input_range,
      data
    )
  end
end

class NightManagerTabController < TabController
  def initialize(date, wb_controller)
    super(wb_controller, TabController.tab_name_for_date(date))
    @date = date
    @title = EventTable.event_title_for_date(date)

    @heading_range = HeadingsRange.new(@wb_controller, sheet_range_from_coordinates("B2:F3"), @tab_name)
    @ticket_sales_range = TicketSalesRange.new(@wb_controller, sheet_range_from_coordinates("B5:F22"), @tab_name)
    @notes_range = NotesRange.new(@wb_controller, sheet_range_from_coordinates("H24:L29"), @tab_name)

    @fee_range = FeeDetailsRange.new(
      @wb_controller, 
      sheet_range_from_coordinates("B24:C29"), 
      @tab_name, 
      @ticket_sales_range, 
      ContractTable.fee_details_for_date(@date)
    )
    @expenses_range = ExpensesRange.new(@wb_controller, sheet_range_from_coordinates("H5:L10"), @tab_name)
    @prs_range = PRSRange.new(@wb_controller, sheet_range_from_coordinates("H12:I15"), @tab_name, @ticket_sales_range)
    @z_readings_range = ZReadingsRange.new(@wb_controller, sheet_range_from_coordinates("K12:L15"), @tab_name)
    @merch_range = MerchRange.new(@wb_controller, sheet_range_from_coordinates("H17:J22"), @tab_name)
  end




  def size_columns()
    requests = [20, 100, 100, 100, 110, 100, 20, 110, 100, 100, 100, 100].each_with_index.collect { |width, i_col|
      set_column_width_request(i_col, width)
    }
    @wb_controller.apply_requests(requests)
  end

  def build_sheet()
    clear_values_and_formats()
    size_columns()
    @heading_range.initialise_range(@date, @title)
    @ticket_sales_range.initialise_range()
    @fee_range.initialise_range()
    @prs_range.initialise_range()
    @notes_range.initialise_range()
    @expenses_range.initialise_range()
    @z_readings_range.initialise_range()
    @merch_range.initialise_range()
  end

  def read_session_data()
    NMForm_SessionData.new(
      mugs: @merch_range.mugs_number_and_value(),
      t_shirts: @merch_range.t_shirts_number_and_value(),
      bags: @merch_range.bags_number_and_value(),
      masks: @merch_range.masks_number_and_value(),
      zettle_z_reading: @z_readings_range.zettle_reading_value(),
      cash_z_reading: @z_readings_range.cash_reading_value(),
      notes: @notes_range.read_merged_note(),
      fee_to_pay: @fee_range.fee_to_pay_value,
      fully_improvised: @prs_range.fully_improvised(),
      prs_to_pay: @prs_range.prs_to_pay_value()
    )
  end

  def read_nm_form_data()
    NMForm_Data.new(
      date: @date,
      session_data: read_session_data(),
      ticket_sales: @ticket_sales_range.read_ticket_sales(),
      expenses_data: @expenses_range.read_expenses()
    )
  end

  def set_nm_form_data(form_data:)
    assert_type(form_data, NMForm_Data)
    @notes_range.write_merged_note(form_data.session_data.notes)
    @expenses_range.write_expenses(form_data.expenses_data)
    @ticket_sales_range.write_ticket_sales(form_data.ticket_sales)
    @prs_range.set_fully_improvised(form_data.session_data.fully_improvised)
    @z_readings_range.set_z_readings(form_data.session_data)
    @merch_range.set_merch_data(form_data.session_data)
  end

end
