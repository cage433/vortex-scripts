require_relative '../env'
require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'
require_relative '../utils/utils'
require_relative '../model/event_personnel'


module VolunteerRotaColumns
  EVENT_ID_COL, DATE_COL, TITLE_COL, DOORS_OPEN_COL, 
    DISPLAY_TITLE_COL, DISPLAY_DATE_COL, DAY_COL, 
    DISPLAY_DOORS_OPEN_COL, NIGHT_MANAGER_COL, 
    VOL_1_COL, VOL_2_COL, VOL_3_COL, SOUND_ENGINEER_COL,
    MEMBER_BOOKINGS_COL, NM_NOTES_COL = [*0..15]
end

class VolunteerMonthTabController < TabController
  HEADER = ["Event ID", "Date", "Title", "Doors Open", "Title", "Date", "Day", "Doors Open", "Night Manager", "Vol 1", "Vol 2", "Vol 3", "Sound", "Members Bookings", "NM Notes"]
  include VolunteerRotaColumns

  def initialize(year_no, month_no, wb_controller)
    super(wb_controller, TabController.tab_name_for_month(year_no, month_no))
    @accounting_year = year_no
    @month_no = month_no
    @width = HEADER.size
    @sheet_range = SheetRange.new(
      SheetCell.from_coordinates("A1"),
      100,
      @width,
      @sheet_id, @tab_name
    )
  end


  def write_header()
    header_range = @sheet_range.row(0)
    @wb_controller.set_data(header_range, [HEADER])
    @wb_controller.apply_requests([
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(DISPLAY_TITLE_COL, 300),
      set_column_width_request(DISPLAY_DATE_COL, 50),
      set_column_width_request(DAY_COL, 50),
      set_column_width_request(MEMBER_BOOKINGS_COL, 300),
      set_column_width_request(NM_NOTES_COL, 300),
    ])
  end

  def format_columns(num_events)
    events_range = @sheet_range.sub_range(relative_row_range: 0..num_events)
    requests = [
      set_date_format_request(single_column_range(DISPLAY_DATE_COL), "mmm d"),
      set_date_format_request(single_column_range(DAY_COL), "ddd"),
      set_outside_border_request(events_range, style: "SOLID_THICK"),
      set_border_request(events_range.column(TITLE_COL), style: "SOLID_THICK", borders: [:left]),
      set_border_request(events_range.column(NIGHT_MANAGER_COL), style: "SOLID_THICK", borders: [:right, :left]),
      set_border_request(events_range.column(SOUND_ENGINEER_COL), style: "SOLID_THICK", borders: [:right, :left]),
      set_row_height_request(0, num_events, 30),
      bold_and_center_request(@sheet_range.row(0)),
      set_border_request(events_range.column(VOL_1_COL), style: "DOTTED", borders: [:right]),
      set_border_request(events_range.column(VOL_2_COL), style: "DOTTED", borders: [:right]),
      set_border_request(events_range.column(MEMBER_BOOKINGS_COL), style: "DOTTED", color: @@black, borders: [:right]),
      bold_text_request(events_range.sub_range(relative_col_range: DISPLAY_TITLE_COL..DISPLAY_DOORS_OPEN_COL)),
    ]

    requests.append(hide_column_request(EVENT_ID_COL, DOORS_OPEN_COL + 1))
    @wb_controller.apply_requests(requests)
  end

  def rows_for_date(personnel_for_date)
    assert_collection_type(personnel_for_date, EventPersonnel)
    sorted_personnel = personnel_for_date.sort{ |l, r| 
      compare_with_nils(l.doors_open, r.doors_open) 
    }
    first_title = sorted_personnel[0].title
    sorted_personnel.each_with_index.collect { |personnel, i|
      display_title = if personnel.title == first_title && i > 0 then "" else personnel.title end
      display_doors_open = if is_nil_or_blank?(personnel.doors_open) then "" else personnel.doors_open.strftime("%H:%M") end
      [
        personnel.airtable_id,
        personnel.date,
        personnel.title,
        personnel.doors_open,
        display_title,
        if i == 0 then personnel.date else "" end,
        if i == 0 then personnel.date else "" end,
        display_doors_open,
        personnel.night_manager,
        personnel.vol1,
        personnel.vol2,
        personnel.vol3,
        personnel.sound_engineer,
        personnel.member_bookings,
        personnel.nm_notes
      ]
    }
  end

  def write_events(events_personnel)
    assert_type(events_personnel, EventsPersonnel)
    data = []
    requests = []
    i_row = 1
    personnel_by_date = events_personnel.events_personnel.group_by{ |ep| ep.date }
    dates = personnel_by_date.keys.sort
    personnel_by_session = []
    # Can have multiple events in a day, so break them into sessions, by using the title
    # then order them by their first door opening time (which can be nil)
    dates.each {|date|
      personnel_for_date = personnel_by_date[date]
      personnel_by_title = personnel_for_date.group_by{ |ep| ep.title }
      titles = personnel_by_title.keys
      sorted_titles = titles.sort_by{ |title| personnel_by_title[title][0].doors_open.to_s}
      sorted_titles.each { |title|
        personnel_by_session.append(personnel_by_title[title])
      }
    }
    personnel_by_session.each_with_index { |personnel_for_session, i_session|
      next_rows = rows_for_date(personnel_for_session)
      range_for_date = @sheet_range.rows(i_row...i_row + next_rows.size)
      requests.append(set_outside_border_request(range_for_date))
      if i_session % 2 == 0
        requests.append(set_background_color_request(range_for_date, @@light_yellow))
      end
      data += next_rows
      i_row += next_rows.size

    }

    @wb_controller.set_data(@sheet_range.rows(1...i_row), data)

    @wb_controller.apply_requests(requests)
  end



  def read_events_personnel()
    rows = @wb_controller.get_spreadsheet_values(@sheet_range.rows(1..))
    if rows.nil?
      EventsPersonnel.new(events_personnel: [])
    else
      events_personnel = rows.filter{|row| !row[EVENT_ID_COL].nil? and row[EVENT_ID_COL].strip != ""}.collect {|row|
          row += [""] * (HEADER.size - row.size) if row.size < HEADER.size
          doors_open = if is_nil_or_blank?(row[DOORS_OPEN_COL]) then nil else Time.parse(row[DOORS_OPEN_COL]) end
          EventPersonnel.new(
            airtable_id: row[EVENT_ID_COL],
            title: row[TITLE_COL],
            date: Date.parse(row[DATE_COL]),
            doors_open: doors_open,
            vol1: row[VOL_1_COL],
            vol2: row[VOL_2_COL],
            vol3: row[VOL_3_COL],
            night_manager: row[NIGHT_MANAGER_COL],
            sound_engineer: row[SOUND_ENGINEER_COL],
            member_bookings: row[MEMBER_BOOKINGS_COL],
            nm_notes: row[NM_NOTES_COL]
          )
      }
      EventsPersonnel.new(events_personnel: events_personnel)
    end
  end

  def replace_events(month_events)
      clear_values_and_formats()
      write_header()
      format_columns(month_events.size)
      write_events(month_events)
  end

end
