require_relative './sheets-service'
require_relative './sheet-range'
require_relative './tab-controller'

module NightManagerColumns


  HEADER = [
    [
      "", "", "", "", "", "", "",
      "Online Sales", "",
      "Walk Ins", "",
      "Guests/Cheap", "",
      "", "", 
      "Band Fee", "",
      "T-shirts Sold", "",
      "Mugs Sold", "",
      ""
    ],
    [
      "Event ID", "Gig ID", "Event", "Date", "Day", "Set No", "Doors Open",
      "Num", "Price (£)", 
      "Num", "Sales (£)",
      "Num", "Sales (£)",
      "Total Sales (£)", "PRS (£)",
      "If 65% (£)", "Other Deal (£)", 
      "Num", "Sales (£)", 
      "Num", "Sales (£)", 
      "Notes"
    ]
  ]
  NUM_COLS = HEADER[0].size
  HEADER_ROWS = HEADER.size

  EVENT_ID_COL, GIG_ID_COL, TITLE_COL, DATE_COL, DAY_COL, GIG_NO_COL, DOORS_OPEN_COL,
    ONLINE_TICKETS_COL, PRICE_COL,
    WALK_INS_COL, WALK_IN_SALES_COL,
    GUESTS_OR_CHEAP_COL, GUEST_OR_CHEAP_SALES_COL,
    TOTAL_SALES_COL,
    PRS_COL,
    FEE_IF_65_COL, FEE_IF_OTHER_COL,
    T_SHIRTS_COL, T_SHIRT_SALES_COL,
    MUGS_COL, MUG_SALES_COL,
    NOTES_COL = [*0..NUM_COLS]
end

class NightManagerEventRange
  include NightManagerColumns
  def initialize(rows)
    # get_spreadsheet_values only returns non-blank rows, 
    # we correct here to force there to be three rows for each event
    @rows = rows.collect { |row|
      row + [""] * (NUM_COLS - row.size)
    }
    @rows.append([[""] * NUM_COLS] * (3 - @rows.size)) 
  end
  def _gig_takings(row)
    GigTakings.new(
      airtable_id: row[GIG_ID_COL],
      gig_no: row[GIG_NO_COL].to_i,
      online_tickets: row[ONLINE_TICKETS_COL].to_i,
      ticket_price: row[PRICE_COL].to_f,
      walk_ins: row[WALK_INS_COL].to_i, walk_in_sales: row[WALK_IN_SALES_COL].to_f,
      guests_or_cheap: row[GUESTS_OR_CHEAP_COL].to_i, guest_or_cheap_sales: row[GUEST_OR_CHEAP_SALES_COL].to_f,
      t_shirts: row[T_SHIRTS_COL].to_i, t_shirt_sales: row[T_SHIRT_SALES_COL].to_f,
      mugs: row[MUGS_COL].to_i, mug_sales: row[MUG_SALES_COL].to_f,
    )
  end

  def as_event()
    NightManagerEvent.new(
      airtable_id: @rows[0][EVENT_ID_COL],
      event_date: Date.parse(@rows[0][DATE_COL]),
      event_title: @rows[0][TITLE_COL],
      gig1_takings: _gig_takings(@rows[0]),
      gig2_takings: _gig_takings(@rows[1]),
    )
  end

end

class NightManagerMonthTabController < TabController
  include NightManagerColumns

  def initialize(year_no, month_no, wb_controller)
    super(wb_controller, TabController.tab_name_for_month(year_no, month_no))
    @year_no = year_no
    @month_no = month_no
  end

  def sheet_range(
    start_row_index, 
    end_row_index, 
    start_column_index = 0, 
    end_column_index = NUM_COLS
  )
    SheetRange.new(start_row_index, end_row_index, start_column_index, end_column_index, @sheet_id, @tab_name)
  end

  def format_columns()
    requests = [
      set_number_format_request(single_column_range(DATE_COL), "mmm d"),
      set_number_format_request(single_column_range(DAY_COL), "ddd"),
    ]

    requests += [EVENT_ID_COL, GIG_ID_COL, GIG_NO_COL].collect { |col| hide_column_request(col)}
    @wb_controller.apply_requests(requests)
  end

  def write_header()
    header_range = sheet_range(0, HEADER_ROWS)
    @wb_controller.set_data(header_range, HEADER)
    requests = [
      unmerge_all_request(),
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(TITLE_COL, 300),
      set_column_width_request(TOTAL_SALES_COL, 200),
      center_text_request(header_range),
    ]
    [ONLINE_TICKETS_COL, WALK_INS_COL, GUESTS_OR_CHEAP_COL, FEE_IF_65_COL, T_SHIRTS_COL, MUGS_COL].each do |i_col|
      requests.append(merge_columns_request(sheet_range(0, 1, i_col, i_col + 2)))
      requests.append(set_left_right_border_request(sheet_range(0, 2, i_col, i_col + 2)))
    end
    requests.append(set_left_right_border_request(sheet_range(0, 2, TOTAL_SALES_COL, TOTAL_SALES_COL + 1)))

    @wb_controller.apply_requests(requests)
  end

  def write_events(month_events)
    num_events = month_events.num_events
    events_range = sheet_range(HEADER_ROWS, HEADER_ROWS + num_events * 3)
    data = []
    def to_night_manager_xl_data(event, i_event)
        i_row = 3 + i_event * 3
        first_row = [
          event.airtable_id, 
          event.gig1_takings.airtable_id, 
          event.event_title, 
          event.event_date, 
          event.event_date,
          1, "19:00",
          event.gig1_takings.online_tickets, event.gig1_takings.ticket_price,
          event.gig1_takings.walk_ins, event.gig1_takings.walk_in_sales,
          event.gig1_takings.guests_or_cheap, event.gig1_takings.guest_or_cheap_sales,
          "=H#{i_row} * I#{i_row} + K#{i_row} + M#{i_row}", 
          "", "", "",
          event.gig1_takings.t_shirts, event.gig1_takings.t_shirt_sales,
          event.gig1_takings.mugs, event.gig1_takings.mug_sales,
          ""
        ] 
        i_row += 1
        second_row = [
          event.airtable_id, 
          event.gig2_takings.airtable_id, 
          "", "", "",
          2, "21:00",
          event.gig2_takings.online_tickets, event.gig2_takings.ticket_price,
          event.gig2_takings.walk_ins, event.gig2_takings.walk_in_sales,
          event.gig2_takings.guests_or_cheap, event.gig2_takings.guest_or_cheap_sales,
          "=H#{i_row} * I#{i_row} + K#{i_row} + M#{i_row}", 
          "", "", "",
          event.gig2_takings.t_shirts, event.gig2_takings.t_shirt_sales,
          event.gig2_takings.mugs, event.gig2_takings.mug_sales,
          ""
        ]
        blank_row = [""] * 20
        [first_row, second_row, blank_row]
    end
    month_events.sorted_events().each_with_index do |event, i_event|
      data += to_night_manager_xl_data(event, i_event)
    end
    @wb_controller.set_data(events_range, data)
    requests = (0...num_events).collect do |i_event|
      event_range = sheet_range(HEADER_ROWS + i_event * 3, HEADER_ROWS + (i_event + 1) * 3)
      set_outside_border_request(event_range)
    end

    @wb_controller.apply_requests(requests)
  end

  def read_events()
    max_events = 50
    event_range = sheet_range(HEADER_ROWS, HEADER_ROWS + 3 * max_events)
    values = @wb_controller.get_spreadsheet_values(event_range)
    if values.nil?
      EventsForMonth.new(@year_no, @month_no, [])
    else
      num_events = (values.size / 3.0).ceil
      events = (0...num_events).collect do |i_event|
        rows_for_event = values.slice(i_event * 3, 3)
        NightManagerEventRange.new(rows_for_event).as_event()
      end
      EventsForMonth.new(@year_no, @month_no, events)
    end
  end

  def replace_events(month_events)
      clear_values()
      write_header()
      format_columns()
      write_events(month_events)
  end
end
