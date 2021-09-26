require_relative './sheets-service'
require_relative './sheet-range'
require_relative './tab-controller'

module VolunteerRotaColumns
  EVENT_ID_COL, DATE_COL, TITLE_COL, DISPLAY_TITLE_COL, DISPLAY_DATE_COL, DAY_COL, 
    DOORS_OPEN_COL, NIGHT_MANAGER_COL, 
    VOL_1_COL, VOL_2_COL, SOUND_ENGINEER_COL = [*0..11]
end

class VolunteerMonthTabController < TabController
  HEADER = ["Event ID", "Date", "Title", "Title", "Date", "Day", "Doors Open", "Night Manager", "Vol 1", "Vol 2", "Sound Engineer"]
  include VolunteerRotaColumns

  def initialize(year_no, month_no, wb_controller)
    super(wb_controller, TabController.tab_name_for_month(year_no, month_no))
    @year_no = year_no
    @month_no = month_no
    @width = HEADER.size
  end

  #def event_range(i_event)
    #sheet_range(1 + i_event * 2, 1 + (i_event + 1) * 2)
  #end



  def write_header()
    header_range = sheet_range(0, 1)
    @wb_controller.set_data(header_range, [HEADER])
    @wb_controller.apply_requests([
      set_background_color_request(header_range, @@light_green),
      set_outside_border_request(header_range),
      set_column_width_request(TITLE_COL, 300)
    ])
  end

  def format_columns()
    requests = [
      set_number_format_request(single_column_range(DATE_COL), "mmm d"),
      set_number_format_request(single_column_range(DAY_COL), "ddd"),
    ]

    requests.append(hide_column_request(EVENT_ID_COL, TITLE_COL + 1))
    @wb_controller.apply_requests(requests)
  end

  def rows_for_date(personnel_for_date)
    assert_type(personnel_for_date, PersonnelForDate)
    first_title = personnel_for_date.events_personnel[0].title
    personnel_for_date.events_personnel.each_with_index.collect { |personnel, i|
      display_title = if personnel.title == first_title && i > 0 then "" else personnel.title end
      [
        personnel.airtable_id,
        personnel.date,
        personnel.title,
        display_title,
        if i == 0 then personnel.date else "" end,
        if i == 0 then personnel.date else "" end,
        personnel.doors_open,
        personnel.night_manager,
        personnel.vol1,
        personnel.vol2,
        personnel.sound_engineer
      ]
    }
  end

  def write_events(personnel_by_date)
    assert_type(personnel_by_date, DatedCollection)
    data = []
    requests = []
    i_row = 1
    personnel_by_date.dates.each_with_index do |d, i_date|
      personnel_for_date = personnel_by_date[d]
      next_rows = rows_for_date(personnel_for_date)
      range_for_date = sheet_range(i_row, i_row + next_rows.size)
      requests.append(set_outside_border_request(range_for_date))
      if i_date % 2 == 0
        requests.append(set_background_color_request(range_for_date, @@light_yellow))
      end
      data += next_rows
      i_row += next_rows.size
    end

    @wb_controller.set_data(sheet_range(1, i_row), data)

    @wb_controller.apply_requests(requests)
  end



  def read_events()

    max_events = 50
    rows = @wb_controller.get_spreadsheet_values(
      sheet_range(1, 1 + 2 * max_events)
    )
    if rows.nil?
      DatedCollection.new([])
    else

      rows_by_date = rows.group_by { |row| Date.parse(row[DATE_COL]) }
      personnel_by_date = rows_by_date.collect { |date, rows_for_date| 
        first_title = rows_for_date[0][TITLE_COL]
        def event_personnel_from_row(row)
          row += [""] * (HEADER.size - row.size) if row.size < HEADER.size
          title = row[TITLE_COL]
          title = first_title if title == ""
          EventPersonnel.new(
            airtable_id: row[GIG_ID_COL],
            title: title,
            date: date,
            doors_open: row[DOORS_OPEN_COL],
            vol1: row[VOL_1_COL],
            vol2: row[VOL_2_COL],
            night_manager: row[NIGHT_MANAGER_COL],
            sound_engineer: row[SOUND_ENGINEER_COL]
          )
        end
        PersonnelForDate.new(
          rows_for_date.collect { |row| event_personnel_from_row(row) }.flatten
        )

      }
      DatedCollection(personnel_by_date)
    end
  end

  def replace_events(month_events)
      clear_values_and_formats()
      write_header()
      format_columns()
      write_events(month_events)
  end

end
