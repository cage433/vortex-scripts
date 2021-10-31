require_relative '../utils/utils'
require 'date'
require 'airrecord'
require_relative '../env'
require_relative '../google-sheets/tab-controller'
require_relative '../google-sheets/workbook_controller'
require_relative '../airtable/contract_table'

######################
#     Model
#######################
class NumberSoldAndValue
  attr_reader :number, :value

  def initialize(number:, value:)
    @number = number
    @value = value
  end
end

class NMForm_PerformanceData
  attr_reader :airtable_id, :performance_date, :mugs, :t_shirts, :masks, :bags, :zettle_z_reading, :cash_z_reading, :notes

  def initialize(airtable_id:, performance_date:, mugs:, t_shirts:, masks:, bags:, zettle_z_reading:, cash_z_reading:, notes:)
    assert_type(performance_date, DateTime)
    [mugs, t_shirts, masks, bags].each do |merch|
      assert_type(merch, NumberSoldAndValue)
    end
    @airtable_id = airtable_id
    @performance_date = performance_date
    @mugs = mugs
    @t_shirts = t_shirts
    @masks = masks
    @bags = bags
    @zettle_z_reading = zettle_z_reading
    @cash_z_reading = cash_z_reading
    @notes = notes
  end
end

class NMForm_GigData
  attr_reader :airtable_id, :performance_date, :gig, :online, :walk_ins, :guests_and_cheap

  def initialize(airtable_id:, performance_date:, gig:, online:, walk_ins:, guests_and_cheap:)
    @airtable_id = airtable_id
    assert_type(performance_date, DateTime)
    [online, walk_ins, guests_and_cheap].each do |x|
      assert_type(x, NumberSoldAndValue)
    end
    @performance_date = performance_date
    @gig = gig
    @online = online
    @walk_ins = walk_ins
    @guests_and_cheap = guests_and_cheap
  end
end

class NMForm_ExpensesData
  attr_reader :airtable_id, :performance_date, :note, :amount

  def initialize(airtable_id:, performance_date:, note:, amount:)
    @airtable_id = airtable_id
    assert_type(performance_date, DateTime)
    @performance_date = performance_date
    @note = note
    @amount = amount
  end
end

######################
#     Airtable
#######################
Airrecord.api_key = AIRTABLE_API_KEY 

module NMForm_Columns
  ID = "Record ID"
  PERFORMANCE_DATE = "Performance Date"
end

class NMForm_Table < Airrecord::Table
  include NMForm_Columns
  def self.base_key 
    VORTEX_DATABASE_ID
  end
  
  def self.records_for_date(date)
    # Ugly-ass nonsense to handle timezone related issues messing up comparisons
    first_date_formatted = (date - 1).strftime("%Y-%m-%d")
    last_date_formatted = (date + 1).strftime("%Y-%m-%d")
    filter_text = "AND({#{PERFORMANCE_DATE}} > '#{first_date_formatted}',{#{PERFORMANCE_DATE}} < '#{last_date_formatted}')"
    all(filter: filter_text)
  end

  def self.destroy_records_for_date(date)
    records_for_date(date).each do |rec|
      rec.destroy
    end
  end
end

module NMForm_PerformanceColumns 
  include NMForm_Columns

  MUGS_NUMBER = "Mugs Number"
  MUGS_VALUE = "Mugs Value"
  MASKS_NUMBER = "Masks Number"
  MASKS_VALUE = "Masks Value"
  T_SHIRTS_NUMBER = "T-shirts Number"
  T_SHIRTS_VALUE = "T-shirts Value"
  BAGS_NUMBER = "Bags Number"
  BAGS_VALUE = "Bags Value"
  ZETTLE_Z_READING = "Zettle Z Reading"
  CASH_Z_READING = "Cash Z Reading"
  NOTES = "Notes"
end

class NMForm_PerformanceTable < NMForm_Table
  include NMForm_PerformanceColumns

  self.table_name = "NM Form (Performance)"

  def self.has_record?(date)
    !id_for_date(date).nil?
  end

  def self.id_for_date(date)
    records = records_for_date(date)
    if records.empty?
      nil
    else
      records[0][ID]
    end
  end

end

module NMForm_GigColumns

  include NMForm_Columns
  GIG = "Gig"
  ONLINE_NUMBER = "Online Number"
  ONLINE_VALUE = "Online Value"
  WALK_IN_NUMBER = "Walk-in Number"
  WALK_IN_VALUE = "Walk-in Value"
  GUESTS_AND_CHEAP_NUMBER = "Guests/Cheap Number"
  GUESTS_AND_CHEAP_VALUE = "Guests/Cheap Value"

  GIG_1 = "Gig 1"
  GIG_2 = "Gig 2"
end

class NMForm_GigTable < NMForm_Table
  include NMForm_GigColumns

  self.table_name = "NM Form (Gig)"


end

module NMForm_ExpensesColumns
  include NMForm_Columns
  NOTE = "Note"
  AMOUNT = "Amount (£)"
end

class NMForm_ExpensesTable < NMForm_Table
  include NMForm_ExpensesColumns

  self.table_name = "NM Form (Expenses)"

end


######################
#     Sheet
#######################

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
    @expenses_range = sheet_range_from_coordinates("H5:L10")
    @prs_range = sheet_range_from_coordinates("H12:I15")
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
    flat_fee_cell, split_cell, ticket_sales_cell, fee_to_pay_cell = (2..5).collect{ |i_row| @fee_range.cell(i_row, 1)}
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
      fee_to_pay_cell, 
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
      set_currency_format_request(fee_to_pay_cell),
    ]
    @wb_controller.apply_requests(requests)
  end

  def build_expenses_range()
    @wb_controller.set_data(
      @expenses_range.cell(0, 0),
      "Expenses"
    )
    @wb_controller.set_data(
      @expenses_range.cell(1, 0),
      "Note"
    )
    @wb_controller.set_data(
      @expenses_range.cell(1, 4),
      "Amount (£)"
    )
    requests = [
      bold_and_center_request(@expenses_range.rows(0..1)),
      set_outside_border_request(@expenses_range),
      set_border_request(@expenses_range.row(1), style: "SOLID", borders: [:bottom]),
      set_border_request(@expenses_range.column(3).rows(1..), style: "SOLID", borders: [:right]),
      merge_columns_request(@expenses_range.row(0)),
      set_background_color_request(@expenses_range.rows(2..), @@almond),
      set_currency_format_request(@expenses_range.column(-1).rows(2..)),
    ]
    (1...@expenses_range.num_rows).each { |i_row|
      requests.push(merge_columns_request(@expenses_range.row(i_row).columns(0..3)))
    }
    @wb_controller.apply_requests(requests)

  end

  def build_prs_range()
    @wb_controller.set_data(
      @prs_range.column(0),
      ["PRS", "", "Fully Improvised", "To Pay"]
    )
    is_fully_improvised_cell = @prs_range.cell(2, 1)
    to_pay_cell = @prs_range.cell(3, 1)
    @wb_controller.set_data(
      to_pay_cell,
      "=if(#{is_fully_improvised_cell.cell_reference}, 0.0, 0.04 * #{@total_ticket_sales.cell_reference})"
    )
    requests = [
      set_outside_border_request(@prs_range),
      set_border_request(@prs_range.row(0), style: "SOLID", borders: [:bottom]),
      merge_columns_request(@prs_range.row(0)),
      bold_text_request(@prs_range.column(0)),
      bold_and_center_request(@prs_range.row(0)),
      create_checkbox_request(is_fully_improvised_cell),
      set_currency_format_request(to_pay_cell),
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
      @merch_range.column(0),
      ["Merch", "", "Mugs", "T-shirts", "Bags", "Masks"]
    )
    @wb_controller.set_data(
      @merch_range.row(1),
      ["", "Number", "Amount (£)"]
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

  def create_sheet_if_necessary(force: false)
    tab_exists = @wb_controller.has_tab_with_name?(@tab_name)
    @wb_controller.add_tab(@tab_name) if !tab_exists
    if !tab_exists || force
      clear_values_and_formats()
      size_columns()
      build_headings_range()
      build_takings_range()
      build_fee_details_range()
      build_prs_range()
      build_notes_range()
      build_expenses_range()
      build_z_readings_range()
      build_merch_range()
    end
  end
end

######################
#     Controller
#######################


class NMFormController

  def self._single_performance_date(datas)
    dates = datas.collect{ |d| d.performance_date }.uniq
    raise "Expected a single performance date, got #{dates}" unless dates.size == 1
    dates[0]
  end

  def self.write_nm_performance_data(data)
    include NMForm_PerformanceColumns
    assert_type(data, NMForm_PerformanceData)
    NMForm_PerformanceTable.destroy_records_for_date(data.performance_date)

    record = NMForm_PerformanceTable.new(PERFORMANCE_DATE => data.performance_date)
    record[PERFORMANCE_DATE] = data.performance_date
    record[MUGS_NUMBER] = data.mugs.number
    record[MUGS_VALUE] = data.mugs.value
    record[T_SHIRTS_NUMBER] = data.t_shirts.number
    record[T_SHIRTS_VALUE] = data.t_shirts.value
    record[MASKS_NUMBER] = data.masks.number
    record[MASKS_VALUE] = data.masks.value
    record[BAGS_NUMBER] = data.bags.number
    record[BAGS_VALUE] = data.bags.value
    record[ZETTLE_Z_READING] = data.zettle_z_reading
    record[CASH_Z_READING] = data.cash_z_reading
    record[NOTES] = data.notes

    record.save
  end


  def self.write_nm_gig_data(datas)
    include NMForm_GigColumns
    raise "Expected two data, got #{datas}" unless datas.size == 2
    assert_collection_type(datas, NMForm_GigData)

    perf_date = _single_performance_date(datas)
    raise "Expected gigs 1 & 2" unless Set[GIG_1, GIG_2] == datas.collect{ |d| d.gig}.to_set

    NMForm_GigTable.destroy_records_for_date(perf_date)

    datas.each { |d|
      record = NMForm_GigTable.new(PERFORMANCE_DATE => d.performance_date)
      record[GIG] = d.gig
      record[ONLINE_NUMBER] = d.online.number
      record[ONLINE_VALUE] = d.online.value
      record[WALK_IN_NUMBER] = d.walk_ins.number
      record[WALK_IN_VALUE] = d.walk_ins.value
      record[GUESTS_AND_CHEAP_NUMBER] = d.guests_and_cheap.number
      record[GUESTS_AND_CHEAP_VALUE] = d.guests_and_cheap.value

      record.save
    }

  end

  def self.write_nm_expenses_data(datas)
    include NMForm_ExpensesColumns
    perf_date = _single_performance_date(datas)
    NMForm_ExpensesTable.destroy_records_for_date(perf_date)

    datas.each { |d|
      record = NMForm_ExpensesTable.new(PERFORMANCE_DATE => d.performance_date)
      record[NOTE] = d.note
      record[AMOUNT] = d.amount

      record.save
    }
  end
end

def spike
  perf_data = NMForm_PerformanceData.new(
    airtable_id: nil,
    performance_date: DateTime.new(2021, 10, 3),
    mugs: NumberSoldAndValue.new(number: 1, value: 8),
    t_shirts: NumberSoldAndValue.new(number: 10, value: 123),
    masks: NumberSoldAndValue.new(number: 2, value: 3.5),
    bags: NumberSoldAndValue.new(number: 4, value: 400),
    zettle_z_reading: 123.5,
    cash_z_reading: 121,
    notes: "blah blah blah"
  )

  gig_datas = [1, 2].collect { |i| 
    NMForm_GigData.new(
      airtable_id: nil,
      performance_date: DateTime.new(2021, 10, 3),
      gig: "Gig #{i}",
      online: NumberSoldAndValue.new(number: i * i, value: 8 + i),
      walk_ins: NumberSoldAndValue.new(number: 3 * i, value: 80 - i),
      guests_and_cheap: NumberSoldAndValue.new(number: 10 * i, value: 18 * i),
    )
  }

  expenses_data = [["Beer", 10.0], ["Gin", 111.0]].collect do |note, amt|
    NMForm_ExpensesData.new(
      airtable_id: nil,
      performance_date: DateTime.new(2021, 10, 1),
      note: note,
      amount: amt
    )
  end

  NMFormController.write_nm_expenses_data(expenses_data)
  NMFormController.write_nm_performance_data(perf_data)
  NMFormController.write_nm_gig_data(gig_datas)
end

def sheet_spike()
    night_manager_controller = WorkbookController.new(NIGHT_MANAGER_SPREADSHEET_ID)
    tab_controller = NightManagerTabController.new(Date.new(2021, 10, 20), night_manager_controller)
    tab_controller.create_sheet_if_necessary(force: true)
end

sheet_spike()
