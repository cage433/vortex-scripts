require_relative '../sheets-service'
require_relative '../sheet-range'
require_relative '../tab-controller'
require_relative '../../mediator/mediator'

module NightManagerColumns


  HEADER = [
    [
      "", "", "", "", "", "", "",
      "Online", "",
      "Other Audience", "",
      "", "", 
      "Band Fee", "",
      "T-shirts", "",
      "Mugs", "",
      ""
    ],
    [
      "Event ID", "Gig ID", "Event", "Date", "Day", "Set No", "Doors Open",
      "Num Tickets", "Price", 
      "Num People", "Paid (£)",
      "Total Ticket Sales (£)", "PRS (£)",
      "If 65% (£)", "If other deal (£)", 
      "Num Sold", "Total (£)", 
      "Num Sold", "Total (£)", 
      "Notes"
    ]
  ]
  NUM_COLS = HEADER[0].size
  HEADER_ROWS = HEADER.size

  EVENT_ID_COL, GIG_ID_COL, TITLE_COL, DATE_COL, DAY_COL, GIG_NO_COL, DOORS_OPEN_COL,
    NUM_ONLINE_COL, FULL_PRICE_COL,
    NUM_OTHER_COL, OTHER_PAID_COL,
    TOTAL_SALES_COL,
    PRS_COL,
    FEE_IF_65_COL, FEE_IF_OTHER_COL,
    T_SHIRTS_SOLD_COL, T_SHIRTS_TOTAL_COL,
    MUGS_SOLD_COL, MUGS_TOTAL_COL,
    NOTES_COL = [*0..NUM_COLS]
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
    end_column_index = 20
  )
    SheetRange.new(start_row_index, end_row_index, start_column_index, end_column_index, @sheet_id, @tab_name)
  end



  def write_header()
    header_range = sheet_range(0, HEADER_ROWS)
    @wb_controller.set_data(header_range, HEADER)
    requests = [
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(TITLE_COL, 300),
      set_column_width_request(TOTAL_SALES_COL, 200),
      center_text_request(header_range),
    ]
    [NUM_ONLINE_COL, NUM_OTHER_COL, FEE_IF_65_COL, T_SHIRTS_SOLD_COL, MUGS_SOLD_COL].each do |i_col|
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
    month_events.sorted_events().each_with_index do |event, i_event|
      data += EventMediator.to_night_manager_xl_data(event, i_event)
    end
    @wb_controller.set_data(events_range, data)
    requests = (0...num_events).collect do |i_event|
      event_range = sheet_range(HEADER_ROWS + i_event * 3, HEADER_ROWS + (i_event + 1) * 3)
      set_outside_border_request(event_range)
    end

    event_date_range = sheet_range(HEADER_ROWS, HEADER_ROWS + num_events * 3, 3, 4)
    event_day_range = sheet_range(HEADER_ROWS, HEADER_ROWS + num_events * 3, 4, 5)
    requests += [
      set_number_format_request(event_date_range, "mmm d"),
      set_number_format_request(event_day_range, "ddd"),
    ]

    requests += [0, 1, 5].collect { |col| hide_column_request(col)}
    @wb_controller.apply_requests(requests)
  end

  def replace_events(month_events)
      clear_values()
      write_header()
      write_events(month_events)
  end
end
