require_relative '../sheets-service'
require_relative '../sheet-range'
require_relative '../sheet-mediator'
require_relative 'model'

class NightManagerMonthTabMediator < SheetMediator
  @@header = [
    "Gigs", "Date", "Day", "Set No", "Full Price Tickets", 
    "Full Price", "Other Audience", "Other Audience Paid", "Total Tickets",
    "PRS", "Band Fee",
    "T-shirts sold", "T-shirts value",
    "Mugs sold", "Mugs value",
    "Notes"
  ]

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
    set_data(header_range, [@@header])
    apply_requests([
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(0, 300)
    ])
  end

  def write_events(month_events)
    num_events = month_events.num_events
    events_range = sheet_range(1, 1 + num_events * 3)
    data = []
    month_events.sorted().each do |details_for_event|
      data += details_for_event.to_excel_data() 
    end
    set_data(events_range, data)
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

    apply_requests(requests)
  end
end

class NightManagerSheetMediator
  attr_reader :spreadsheet_id, :service


  def initialize(spreadsheet_id)
    @service = get_sheets_service()
    @spreadsheet_id = spreadsheet_id
  end

  def self.sheet_name_for_month(year, month)
    return Date.new(year, month, 1).strftime("%B %y")
  end

  def has_sheet_for_month?(year, month)
    name_for_month = NightManagerSheetMediator.sheet_name_for_month(year, month)
    sheet_ids_by_name().has_key?(name_for_month)
  end

  def sheet_id_for_month(year, month)
    raise "No sheet called #{name_for_month}" if !has_sheet_for_month?(year, month)
    sheet_ids_by_name()[NightManagerSheetMediator.sheet_name_for_month(year, month)]
  end

  def month_sheet_medtiator(year, month)
    name_for_month = NightManagerSheetMediator.sheet_name_for_month(year, month)
    raise "No sheet called #{name_for_month}" if !has_sheet_for_month?(year, month)
    sheet_id = sheet_ids_by_name()[NightManagerSheetMediator.sheet_name_for_month(year, month)]
    NightManagerMonthTabMediator.new(@service, @spreadsheet_id, name_for_month, sheet_id)
  end

  def apply_request(request)
		result = @service.batch_update_spreadsheet(
		  @spreadsheet_id, 
		  {requests: [request]},
		  fields: nil, quota_user: nil, options: nil
      
		)
  end
  def add_sheet_for_month(year, month)
    name_for_month = NightManagerMonthTabMediator.sheet_name_for_month(year, month)
    raise "Sheet called #{name_for_month} already exists" if has_sheet_for_month?(year, month)
    request = {
      add_sheet: {
        properties: {
          title: name_for_month,
          grid_properties: {hide_gridlines: true}
        }
      }
    }
    apply_request(request)
    puts("Created sheet for #{name_for_month}")
  end

  def delete_sheet_for_month(year, month)
    name_for_month = NightManagerSheetMediator.sheet_name_for_month(year, month)
    raise "Sheet called #{name_for_month} doesn't exist" if !has_sheet_for_month?(year, month)
    request = {
      delete_sheet: {
        sheet_id: sheet_id_for_month(year, month)
      }
    }
    apply_request(request)
    puts("Deleted sheet for #{name_for_month}")
  end
end
