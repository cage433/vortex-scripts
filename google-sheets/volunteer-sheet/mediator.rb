require_relative '../sheets-service'
require_relative '../sheet-range'
require_relative '../sheet-mediator'
require_relative 'model'
require_relative '../../mediator/mediator'

class VolunteerMonthSheetMediator < SheetMediator
  @@header = ["Gigs", "Date", "Day", "Set No", "Doors Open", "Night Manager", "Vol 1", "Vol 2", "Sound Engineer"]

  def initialize(year_no, month_no, wb_controller, sheet_name, sheet_id)
    super(wb_controller, sheet_name, sheet_id)
    @year_no = year_no
    @month_no = month_no
  end

  def sheet_range(
    start_row_index, 
    end_row_index, 
    start_column_index = 0, 
    end_column_index = @@header.size
  )
    SheetRange.new(start_row_index, end_row_index, start_column_index, end_column_index, @sheet_id, @sheet_name)

  end


  def write_header()
    header_range = sheet_range(0, 1)
    @wb_controller.set_data(header_range, [@@header])
    @wb_controller.apply_requests([
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(0, 300)
    ])
  end

  def write_events(month_events)
    num_events = month_events.num_events
    events_range = sheet_range(1, 1 + num_events * 2)
    data = []
    month_events.sorted_events().each do |details_for_event|
      data += EventMediator.to_excel_data(details_for_event) 
    end
    @wb_controller.set_data(events_range, data)
    requests = (0...num_events).collect do |i_event|
      event_range = sheet_range(1 + i_event * 2, 1 + (i_event + 1) * 2)
      set_outside_border_request(event_range)
    end

    event_date_range = sheet_range(1, 1 + num_events * 2, 1, 2)
    event_day_range = sheet_range(1, 1 + num_events * 2, 2, 3)
    requests += [
      set_number_format_request(event_date_range, "mmm d"),
      set_number_format_request(event_day_range, "ddd"),
    ]

    @wb_controller.apply_requests(requests)
  end

  def read_events_from_sheet()
    max_events = 50
    event_range = sheet_range(1, 1 + 2 * max_events)
    values = @wb_controller.get_spreadsheet_values(event_range)
    if values.nil?
      EventsForMonth.new(@year_no, @month_no, [])
    else
      if values.size % 2 == 1
      # get_spreadsheet_values only returns non-blank rows, we correct here to force there
      # to be two rows for each event
        values += [[""] * @@header.size]
      end
      num_events = values.size / 2 
      details = (0...num_events).collect do |i_event|
        rows_for_event = values.slice(i_event * 2, 2).collect do |row|
          # Pad with blanks in case there is no volunteer/engineer data
          row + [""] * (@@header.size - row.size)
        end
        EventMediator.from_excel(rows_for_event)
      end
      EventsForMonth.new(@year_no, @month_no, details)
    end
  end

end
