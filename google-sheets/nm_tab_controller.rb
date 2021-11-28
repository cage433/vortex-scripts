require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

class ExpensesRange < TabController
  def initialize(wb_controller, range, tab_name)
    super(wb_controller, tab_name)
    @range = range
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
      set_background_color_request(@range.rows(2..), @@almond),
      set_currency_format_request(@range.column(-1).rows(2..)),
    ]
    (1...@range.num_rows).each { |i_row|
      requests.push(merge_columns_request(@range.row(i_row).columns(0..3)))
    }
    @wb_controller.apply_requests(requests)
  end

  def read_expenses()
    expenses_data = get_spreadsheet_values(@range.rows(2..)) || []
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
end

class NightManagerTabController < TabController
  def initialize(date, wb_controller)
    super(wb_controller, TabController.tab_name_for_date(date))
    @date = date
    @title = EventTable.event_title_for_date(date)

    @heading_range = sheet_range_from_coordinates("B2:F3")
    @date_cell = @heading_range.cell(0, 1)
    @title_cell = @heading_range.cell(1, 1)


    @takings_range = sheet_range_from_coordinates("B5:F22")
    @takings_row_titles = @takings_range.columns(0..1)
    @total_ticket_sales = @takings_range.cell(-1, -1)

    @notes_range = sheet_range_from_coordinates("H24:L29")
    @fee_range = sheet_range_from_coordinates("B24:C29")
    @fee_to_pay_cell = @fee_range.cell(5, 1)
    @expenses_range = ExpensesRange.new(@wb_controller, sheet_range_from_coordinates("H5:L10"), @tab_name)
    @prs_range = sheet_range_from_coordinates("H12:I15")
    @prs_to_pay_cell = @prs_range.cell(3, 1)
    @z_readings_range = sheet_range_from_coordinates("K12:L15")
    @merch_range = sheet_range_from_coordinates("H17:J22")
  end

  def build_headings_range()
    @wb_controller.set_data(@heading_range.columns(0..1), [["Date", @date], ["Title", @title]])
    requests = [
      set_date_format_request(@date_cell, "d mmm yy"),
      right_align_text_request(@title_cell),
      text_format_request(@heading_range, {bold: true, font_size: 14}),
      set_outside_border_request(@heading_range),
      merge_columns_request(@heading_range.row(0).columns(1..4)),
      merge_columns_request(@heading_range.row(1).columns(1..4)),
    ]

    @wb_controller.apply_requests(requests)
  end

  def build_takings_range()
    @wb_controller.set_data(
      @takings_row_titles,
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
      @takings_range.row(1), 
      ["", "", "Gig 1", "Gig 2", "Total"]
    )

    [4, 5, 8, 9, 12, 13, 16, 17].each do |i_row|
      row = @takings_range.row(i_row)
      sum_refs = [2, 3].collect{ |i_col| row.cell(i_col).cell_reference()}.join("+")
      
      @wb_controller.set_data( row.cell(4), "=#{sum_refs}" 
      )
    end
    [2, 3].each do |i_col|
      col = @takings_range.column(i_col)

      sum_ticket_refs = [4, 8, 12].collect{ |i_row| col.cell(i_row).cell_reference()}.join("+")
      @wb_controller.set_data( col.cell(16), "=#{sum_ticket_refs}" )

      sum_amount_refs = [5, 9, 13].collect{ |i_row| col.cell(i_row).cell_reference()}.join("+")
      @wb_controller.set_data( col.cell(17), "=#{sum_amount_refs}" )
    end

    requests = [
      set_outside_border_request(@takings_range),
      text_format_request(@takings_row_titles, {bold: true}),
      text_format_request(@takings_range.rows(0..1), {bold: true}),
      set_top_bottom_border_request(@takings_range.rows(2..5)),
      set_top_bottom_border_request(@takings_range.rows(10..13)),
      set_left_right_border_request(@takings_range.rows(1..).columns(2..3)),
      merge_columns_request(@takings_range.row(0)),
      center_text_request(@takings_range.rows(0..1)),
    ]
    [4, 8, 12].each do |i_row|
      requests.push(
        set_background_color_request(
          @takings_range.rows(i_row..i_row+1).columns(2..3), 
          @@almond
        )
      )
    end
    [5, 9, 13].each do |i_row|
      requests.push(
        set_currency_format_request(@takings_range.row(i_row).columns(2..4))
      )
    end

    @wb_controller.apply_requests(requests)
  end

  def build_notes_range()
    @wb_controller.set_data(
      @notes_range.cell(0, 0), 
      "Notes"
    )
    requests = [
      set_outside_border_request(@notes_range),
      set_border_request(@notes_range.row(0), style: "SOLID", borders: [:bottom]),
      set_background_color_request(@notes_range.rows(1..), @@almond),
      bold_and_center_request(@notes_range.row(0)),
    ]
    (0...@notes_range.num_rows).each { |i_row|
      requests.push(merge_columns_request(@notes_range.row(i_row)))
    }
    @wb_controller.apply_requests(requests)
  end

  def build_fee_details_range()
    fee_details = ContractTable.fee_details_for_date(@date)
    flat_fee_cell, split_cell, ticket_sales_cell = (2..4).collect{ |i_row| @fee_range.cell(i_row, 1)}
    @wb_controller.set_data(
      @fee_range.column(0),
      [
        "Band Fee",
        "",
        "Flat Fee",
        "Split",
        "Ticket Sales",
        "Fee to pay"
      ]
    )
    @wb_controller.set_data(flat_fee_cell, fee_details.flat_fee)
    @wb_controller.set_data(split_cell, fee_details.percentage_split)
    @wb_controller.set_data(
      ticket_sales_cell, 
        "=#{@total_ticket_sales.cell_reference}"
    )
    @wb_controller.set_data(
      @fee_to_pay_cell, 
      if fee_details.vs_fee 
        "=max(#{flat_fee_cell.cell_reference}, #{split_cell.cell_reference} * #{@total_ticket_sales.cell_reference})"
      else
        "=#{flat_fee_cell.cell_reference} + #{split_cell.cell_reference} * #{@total_ticket_sales.cell_reference}"
      end
    )

    requests = [
      set_outside_border_request(@fee_range),
      set_border_request(@fee_range.row(0), style: "SOLID", borders: [:bottom]),
      merge_columns_request(@fee_range.row(0)),
      bold_text_request(@fee_range.column(0)),
      bold_and_center_request(@fee_range.row(0)),
      set_currency_format_request(flat_fee_cell),
      set_percentage_format_request(split_cell),
      set_currency_format_request(@fee_to_pay_cell),
    ]
    @wb_controller.apply_requests(requests)
  end


  def build_prs_range()
    @wb_controller.set_data(
      @prs_range.column(0),
      ["PRS", "", "Fully Improvised", "To Pay"]
    )
    is_fully_improvised_cell = @prs_range.cell(2, 1)
    @wb_controller.set_data(
      @prs_to_pay_cell,
      "=if(#{is_fully_improvised_cell.cell_reference}, 0.0, 0.04 * #{@total_ticket_sales.cell_reference})"
    )
    requests = [
      set_outside_border_request(@prs_range),
      set_border_request(@prs_range.row(0), style: "SOLID", borders: [:bottom]),
      merge_columns_request(@prs_range.row(0)),
      bold_text_request(@prs_range.column(0)),
      bold_and_center_request(@prs_range.row(0)),
      create_checkbox_request(is_fully_improvised_cell),
      set_currency_format_request(@prs_to_pay_cell),
      set_background_color_request(is_fully_improvised_cell, @@almond),
    ]
    @wb_controller.apply_requests(requests)

  end

  def build_z_readings_range()
    @wb_controller.set_data(
      @z_readings_range.column(0),
      ["Z Readings", "", "Cash (£)", "Zettle (£)"]
    )
    amounts_range = @z_readings_range.rows(2..3).column(1)
    requests = [
      set_outside_border_request(@z_readings_range),
      set_border_request(@z_readings_range.row(0), style: "SOLID", borders: [:bottom]),
      merge_columns_request(@z_readings_range.row(0)),
      bold_and_center_request(@z_readings_range.column(0)),
      set_currency_format_request(amounts_range),
      set_background_color_request(amounts_range, @@almond),
    ]
    @wb_controller.apply_requests(requests)

  end

  def build_merch_range()
    @wb_controller.set_data(
      @merch_range.column(0).rows(2..5),
      ["Mugs", "T-shirts", "Bags", "Masks"]
    )
    @wb_controller.set_data(
      @merch_range.row(1).columns(1..2),
      ["Number", "Amount (£)"]
    )
    input_range = @merch_range.rows(2..).columns(1..)
    titles_range = @merch_range.rows(0..1)
    requests = [
      set_outside_border_request(@merch_range),
      set_border_request(@merch_range.row(1), style: "SOLID", borders: [:bottom]),
      set_border_request(@merch_range.column(0).rows(1..), style: "SOLID", borders: [:right]),
      merge_columns_request(@merch_range.row(0)),
      bold_and_center_request(titles_range),
      bold_text_request(@merch_range.column(0)),
      set_background_color_request(input_range, @@almond),
      set_currency_format_request(input_range.column(1)),
    ]
    @wb_controller.apply_requests(requests)

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
    build_headings_range()
    build_takings_range()
    build_fee_details_range()
    build_prs_range()
    build_notes_range()
    @expenses_range.initialise_range()
    build_z_readings_range()
    build_merch_range()
  end

  def get_cell_value(cell)
    @wb_controller.get_cell_value(cell)
  end

  def read_session_data()
    merch_data = get_spreadsheet_values(@merch_range.rows(2..).columns(1..)) || []
    def number_and_value(merch_data, i_row)
      if i_row >= merch_data.size
        NumberSoldAndValue.new(number: 0, value: 0)
      else
        NumberSoldAndValue.new(
          number: merch_data[i_row][0],
          value: merch_data[i_row][1]
        )
      end
    end
    notes = (get_spreadsheet_values(@notes_range.rows(1..)) || []).collect{ |row| row[0]}.filter { |note| !note.nil? && note.strip != ""}
    merged_note = if notes.size > 0 then notes.join("\n") else nil end
    fee_to_pay = get_cell_value(@fee_to_pay_cell) || 0.0
    prs_to_pay = get_cell_value(@prs_to_pay_cell) || 0.0
    NMForm_SessionData.new(
      mugs: number_and_value(merch_data, 0),
      t_shirts: number_and_value(merch_data, 1),
      bags: number_and_value(merch_data, 2),
      masks: number_and_value(merch_data, 3),
      zettle_z_reading: get_cell_value(@z_readings_range.cell(3, 1)),
      cash_z_reading: get_cell_value(@z_readings_range.cell(2, 1)),
      notes: merged_note,
      fee_to_pay: fee_to_pay,
      prs_to_pay: prs_to_pay
    )
  end

  def read_gigs_data()
    takings_data = get_spreadsheet_values(@takings_range.rows(4..13).columns(2..3)) || []
    if takings_data.size < 10
      takings_data += [0, 0] * (10 - takings_data.size)
    end
    
    def number_and_value(data, i_col)
      NumberSoldAndValue.new(number: data[0][i_col], value: data[1][i_col])
    end
    def gig_data(takings_data, i_col)
      online = takings_data[0..1]
      walk_ins = takings_data[4..5]
      guests = takings_data[8..9]
      NMForm_GigData.new(
        gig: "Gig #{i_col + 1}",
        online: number_and_value(online, i_col),
        walk_ins: number_and_value(walk_ins, i_col),
        guests_and_cheap: number_and_value(guests, i_col),
      )
    end
    (0..1).collect{ |i_gig| gig_data(takings_data, i_gig) }
  end

  def nm_form_data()
    NMForm_Data.new(
      date: @date,
      session_data: read_session_data(),
      gigs_data: read_gigs_data(),
      expenses_data: @expenses_range.read_expenses()
    )
  end

end
