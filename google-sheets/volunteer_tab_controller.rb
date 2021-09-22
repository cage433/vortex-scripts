require_relative './sheets-service'
require_relative './sheet-range'
require_relative './tab-controller'

module VolunteerRotaColumns
  EVENT_ID_COL, GIG_ID_COL, TITLE_COL, DATE_COL, DAY_COL, 
    GIG_NO_COL, DOORS_OPEN_COL, NIGHT_MANAGER_COL, 
    VOL_1_COL, VOL_2_COL, SOUND_ENGINEER_COL = [*0..10]
end

class VolunteerMonthTabController < TabController
  HEADER = ["Event ID", "Gig ID", "Event", "Date", "Day", "Set No", "Doors Open", "Night Manager", "Vol 1", "Vol 2", "Sound Engineer"]
  include VolunteerRotaColumns

  def initialize(year_no, month_no, wb_controller)
    super(wb_controller, TabController.tab_name_for_month(year_no, month_no))
    @year_no = year_no
    @month_no = month_no
    @width = HEADER.size
  end

  def event_range(i_event)
    sheet_range(1 + i_event * 2, 1 + (i_event + 1) * 2)
  end



  def write_header()
    header_range = sheet_range(0, 1)
    @wb_controller.set_data(header_range, [HEADER])
    @wb_controller.apply_requests([
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(0, 300)
    ])
  end

  def format_columns()
    requests = [
      set_number_format_request(single_column_range(DATE_COL), "mmm d"),
      set_number_format_request(single_column_range(DAY_COL), "ddd"),
    ]

    requests += [EVENT_ID_COL, GIG_ID_COL, GIG_NO_COL].collect { |col| hide_column_request(col)}
    @wb_controller.apply_requests(requests)
  end

  def write_events(month_events)
    num_events = month_events.num_events
    events_range = sheet_range(1, 1 + num_events * 2)
    data = []
    month_events.sorted_events().each do |event|
      row1 = [
        event.airtable_id, 
        event.gig1.airtable_id, 
        event.event_title, 
        event.event_date, 
        event.event_date, 
        1, 
        "19:00", 
        event.gig1.night_manager, 
        event.gig1.vol1, 
        event.gig1.vol2, 
        event.sound_engineer
      ]
      row2 = [
        "",
        event.gig2.airtable_id,
        "",
        "",
        "",
        2,
        "21:00",
        "",
        event.gig2.vol1, 
        event.gig2.vol2, 
        ""
      ]
      data += [row1, row2]
    end
    @wb_controller.set_data(events_range, data)
    requests = (0...num_events).collect do |i_event|
      set_outside_border_request(event_range(i_event))
    end

    @wb_controller.apply_requests(requests)
  end



  def read_events()

    def event_from_rows(rows)
      # get_spreadsheet_values only returns non-blank rows, we correct here to 
      # force there to be two rows for each event
      
      rows.append([[""] * HEADER.size]) if rows.size < 2

      def gig_from_row(row)
        row += [""] * (HEADER.size - row.size) if row.size < HEADER.size
        Gig.new(
          airtable_id: row[GIG_ID_COL],
          gig_no: row[GIG_NO_COL],
          vol1: row[VOL_1_COL],
          vol2: row[VOL_2_COL],
          night_manager: row[NIGHT_MANAGER_COL]
        )
      end

      Event.new(
        airtable_id: rows[0][EVENT_ID_COL],
        event_date: Date.parse(rows[0][DATE_COL]),
        event_title: rows[0][TITLE_COL],
        gig1: gig_from_row(rows[0]), 
        gig2: gig_from_row(rows[1]),
        sound_engineer: rows[0][SOUND_ENGINEER_COL]
      )
    end
    max_events = 50
    values = @wb_controller.get_spreadsheet_values(
      sheet_range(1, 1 + 2 * max_events)
    )
    if values.nil?
      EventsCollection.new([])
    else
      num_events = (values.size / 2.0).ceil   # round up to ensure a blank row doesn't exclude an event
      details = (0...num_events).collect do |i_event|
        event_from_rows(values.slice(i_event * 2, 2))
      end
      EventsCollection.new(details)
    end
  end

  def replace_events(month_events)
      clear_values()
      write_header()
      format_columns()
      write_events(month_events)
  end

end
