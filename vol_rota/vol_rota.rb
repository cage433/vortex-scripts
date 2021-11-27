require 'airrecord'
require_relative '../airtable/vortex_table'
require_relative '../env'
require_relative '../google-sheets/tab-controller'
require_relative '../google-sheets/workbook_controller'
require_relative '../utils/utils'

######################
#     Model
#######################

class EventPersonnel 
  attr_reader :airtable_id, :title, :date, :doors_open, :vol1, :vol2, :night_manager, :sound_engineer

  def initialize(airtable_id:, title:, date:, doors_open:, vol1:, vol2:, night_manager:, sound_engineer:)
    assert_type(doors_open, Time, allow_null: true)
    @airtable_id = airtable_id
    @title = title
    @date = date
    @doors_open = doors_open
    @vol1 = vol1
    @vol2 = vol2
    @night_manager = night_manager
    @sound_engineer = sound_engineer
  end

  #def state
    #[@airtable_id, @title, @date, @doors_open, @vol1, @vol2, @night_manager, @sound_engineer]
  #end

  def to_s_table(indent)
    [
      "Title:           #{@title}",
      "Date:            #{@date}",
      "Doors:           #{@doors_open}",
      "Vol1:            #{@vol1}",
      "Vol2:            #{@vol2}",
      "NM:              #{@night_manager}",
      "SE:              #{@sound_engineer}",
    ].collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("")
  end

  def personnel_match(rhs)
    raise "Mismatching ids" unless airtable_id == rhs.airtable_id
    EventPersonnel.states_match(personnel_state, rhs.personnel_state)
  end

  def metadata_match(rhs)
    EventPersonnel.states_match(metadata_state, rhs.metadata_state)
  end

  def state
    [@title, @date, @doors_open, @vol1, @vol2, @night_manager, @sound_engineer, @sound_engineer]
  end

  def matches(rhs)
    EventPersonnel.states_match(state, rhs.state)
  end

  def personnel_state
    [@vol1, @vol2, @night_manager, @sound_engineer]
  end

  def metadata_state
    [@title, @date, @doors_open, @sound_engineer]
  end

  def with_metadata_from(rhs)
    EventPersonnel.new(
      airtable_id:    @airtable_id,
      title:          rhs.title,
      date:           rhs.date, 
      doors_open:     rhs.doors_open,
      vol1:           @vol1,
      vol2:           @vo2,
      night_manager:  @night_manager,
      sound_engineer: rhs.sound_engineer
    )
  end

  def self.states_match(l, r)
    raise "State lengths differ" unless l.size == r.size
    l.zip(r).all? { |l, r|
      is_equal_ignoring_nil_or_blank?(l, r)
    }
  end
end

class EventsPersonnel
  attr_reader :events_personnel, :airtable_ids
  def initialize(events_personnel:)
    assert_collection_type(events_personnel, EventPersonnel)
    @events_personnel = events_personnel
    @events_personnel_by_id = Hash[ *events_personnel.collect { |e| [e.airtable_id, e ] }.flatten ]
    @airtable_ids = events_personnel.collect{ |p| p.airtable_id }.sort
  end
  
  def [](id)
    @events_personnel_by_id[id]
  end

  def include?(id)
    @events_personnel_by_id.include?(id)
  end

  def add_missing(rhs)
    merged_events_personnel = [*@events_personnel]
    rhs.events_personnel.each do |ep|
      if !include?(ep.airtable_id)
        merged_events_personnel.push(ep)
      end
    end
    EventsPersonnel.new(events_personnel: merged_events_personnel)
  end

  def size
    @events_personnel.size
  end

  def changed_personnel(rhs)
    assert_type(rhs, EventsPersonnel)
    EventsPersonnel.new(
      events_personnel: @events_personnel.filter { |ep| !ep.personnel_match(rhs[ep.airtable_id]) }
    )
  end

  def matches(rhs)
    assert_type(rhs, EventsPersonnel)
    if @airtable_ids != rhs.airtable_ids
      false
    else 
      @airtable_ids.all? { |id| @events_personnel_by_id[id].matches(rhs[id])}
    end
  end
end


######################
#     Sheet
#######################


module VolunteerRotaColumns
  EVENT_ID_COL, DATE_COL, TITLE_COL, DOORS_OPEN_COL, 
    DISPLAY_TITLE_COL, DISPLAY_DATE_COL, DAY_COL, 
    DISPLAY_DOORS_OPEN_COL, NIGHT_MANAGER_COL, 
    VOL_1_COL, VOL_2_COL, SOUND_ENGINEER_COL = [*0..12]
end

class VolunteerMonthTabController < TabController
  HEADER = ["Event ID", "Date", "Title", "Doors Open", "Title", "Date", "Day", "Doors Open", "Night Manager", "Vol 1", "Vol 2", "Sound Engineer"]
  include VolunteerRotaColumns

  def initialize(year_no, month_no, wb_controller)
    super(wb_controller, TabController.tab_name_for_month(year_no, month_no))
    @year_no = year_no
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
      set_column_width_request(DISPLAY_TITLE_COL, 300)
    ])
  end

  def format_columns()
    requests = [
      set_date_format_request(single_column_range(DISPLAY_DATE_COL), "mmm d"),
      set_date_format_request(single_column_range(DAY_COL), "ddd"),
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
        personnel.sound_engineer
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
    dates.each_with_index do |d, i_date|
      personnel_for_date = personnel_by_date[d]
      next_rows = rows_for_date(personnel_for_date)
      range_for_date = @sheet_range.rows(i_row...i_row + next_rows.size)
      requests.append(set_outside_border_request(range_for_date))
      if i_date % 2 == 0
        requests.append(set_background_color_request(range_for_date, @@light_yellow))
      end
      data += next_rows
      i_row += next_rows.size
    end

    @wb_controller.set_data(@sheet_range.rows(1...i_row), data)

    @wb_controller.apply_requests(requests)
  end



  def read_events_personnel()

    rows = @wb_controller.get_spreadsheet_values(@sheet_range.rows(1..))
    if rows.nil?
      EventsPersonnel.new(events_personnel: [])
    else
      events_personnel = rows.collect {|row|
          row += [""] * (HEADER.size - row.size) if row.size < HEADER.size
          doors_open = if is_nil_or_blank?(row[DOORS_OPEN_COL]) then nil else Time.parse(row[DOORS_OPEN_COL]) end
          EventPersonnel.new(
            airtable_id: row[EVENT_ID_COL],
            title: row[TITLE_COL],
            date: Date.parse(row[DATE_COL]),
            doors_open: doors_open,
            vol1: row[VOL_1_COL],
            vol2: row[VOL_2_COL],
            night_manager: row[NIGHT_MANAGER_COL],
            sound_engineer: row[SOUND_ENGINEER_COL]
          )
      }
      EventsPersonnel.new(events_personnel: events_personnel)
    end
  end

  def replace_events(month_events)
      clear_values_and_formats()
      write_header()
      format_columns()
      write_events(month_events)
  end

end


######################
#     Airtable
#######################

Airrecord.api_key = AIRTABLE_API_KEY 

module EventTableColumns
  TABLE = "Events"

  ID = "Record ID"
  SHEETS_EVENT_TITLE = "SheetsEventTitle"
  EVENT_DATE = "Event Date"
  DOORS_TIME = "Doors Time"
  SOUND_ENGINEER = "Sound Engineer"
  NIGHT_MANAGER_NAME = "Night Manager Name"
  VOL_1 = "Vol 1 Name"
  VOL_2 = "Vol 2 Name"
  STATUS = "Status"
end

class EventTable < Airrecord::Table

  include EventTableColumns
   
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  def self._select(fields:, first_date:, last_date:)
    select_with_date_filter(
      table: EventTable,
      fields: fields,
      date_field: EVENT_DATE,
      first_date: first_date,
      last_date: last_date,
      extra_filters: ["{#{STATUS}} = 'Confirmed'"]
    )
  end

  def self.ids_for_month(year, month_no)
    _select(
      fields: [ID],
      first_date: Date.new(year, month_no, 1),
      last_date: Date.new(year, month_no, -1)
    ).collect { |rec| rec[ID] }
  end


  def self.event_title_for_date(date)
    recs = _select(
      fields: [SHEETS_EVENT_TITLE],
      first_date: date,
      last_date: date
    )
    titles = recs.collect { |rec| rec[SHEETS_EVENT_TITLE] }.uniq

    if titles.size == 1
      titles[0]
    else
      raise "Expected a single title, got #{titles}"
    end
  end
  

end

class FeeDetails
  attr_reader :flat_fee, :percentage_split, :vs_fee, :error_text

  def initialize(flat_fee:, percentage_split:, vs_fee:, error_text:)
    assert_type(flat_fee, Numeric)
    assert_type(percentage_split, Numeric)
    @flat_fee = flat_fee
    @percentage_split = percentage_split
    @vs_fee = vs_fee
    @error_text = error_text
  end

  def self.error_details(error_text)
    FeeDetails.new(flat_fee: 0, percentage_split: 0, vs_fee: false, error_text: error_text)
  end

  def to_s
    "Fee(flat: #{@flat_fee}, %age: #{@percentage_split}, VS: #{@vs_fee}, error: #{@error_text || 'None'})"
  end
  def has_flat_fee?
    @flat_fee > 0
  end
  def has_percentage?
    @percentage_split > 0
  end
end

module ContractTableColumns
  EVENT_TITLE = "Event title"
  PERFORMANCE_DATE = "Performance date"
  VS_FEE = "VS fee?"
  PERCENTAGE_SPLIT_TO_ARTIST = "Percentage split to Artist"
  FLAT_FEE_TO_ARTIST = "Flat Fee to Artist"
end

class ContractTable < Airrecord::Table
  include ContractTableColumns
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = "Contracts"

  def self.fee_details_for_date(date)
    recs = select_with_date_filter(
      table: ContractTable,
      fields: [EVENT_TITLE, VS_FEE, PERCENTAGE_SPLIT_TO_ARTIST, FLAT_FEE_TO_ARTIST],
      date_field: PERFORMANCE_DATE,
      first_date: date, 
      last_date: date
    )

    if recs.size != 1
      FeeDetails.error_details("Expected a single contract, got #{recs.size} for date #{date}")
    else
      rec = recs[0]
      percentage_split = rec[PERCENTAGE_SPLIT_TO_ARTIST].to_f
      flat_fee = rec[FLAT_FEE_TO_ARTIST].to_f
      vs_fee = (rec[VS_FEE] || false)
      FeeDetails.new(flat_fee: flat_fee, percentage_split: percentage_split, vs_fee: vs_fee, error_text: nil)
    end
  end
end

module ContactsTableMeta
  ID = "Record ID"
  ROLE = "Role"
  TABLE = "Contacts"
  FULL_NAME = "Full Name"
end

class ContactsTable < Airrecord::Table
  include ContactsTableMeta
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

end

class SoundEngineers
  include ContactsTableMeta
  def initialize()
    recs = ContactsTable.all(
      fields:[ID, FULL_NAME],
      filter: "{#{ROLE}} = 'Sound Engineer'"
    )
    @engineers_by_id = Hash[ *recs.collect { |rec| [rec[ID], rec[FULL_NAME]]}.flatten ]
  end

  def [](id)
    @engineers_by_id[id]
  end
end

class VolunteerAirtableController
  include EventTableColumns

  def self.door_time(rec)
    if rec[DOORS_TIME].nil?
      nil
    else
      Time.parse(rec[DOORS_TIME])
    end
  end

  def self._event_title(rec)
    title = rec[SHEETS_EVENT_TITLE]
    if title.class == Array
      raise "Invalid title array #{title.join(", ")}" unless title.size == 1
      title = title[0]
    end
    if title.nil?
      title = ""
    end
    title
  end

  def self.read_events_personnel(year, month)
    event_ids = EventTable.ids_for_month(year, month)
    event_records = EventTable.find_many(event_ids)
    sound_engineers = SoundEngineers.new()
    events_personnel = event_records.collect { |rec|
      sound_engineer = if is_nil_or_blank?(rec[SOUND_ENGINEER]) then
                         nil
                       else
                         sound_engineers[rec[SOUND_ENGINEER][0]]
                       end

      EventPersonnel.new(
        airtable_id: rec[ID], 
        title: self._event_title(rec),
        date: Date.parse(rec[EVENT_DATE]),
        doors_open: self.door_time(rec),
        vol1: rec[VOL_1],
        vol2: rec[VOL_2],
        night_manager: rec[NIGHT_MANAGER_NAME],
        sound_engineer: sound_engineer
      )
    }
    EventsPersonnel.new(events_personnel: events_personnel)

  end


  def self.update_events_personnel(events_personnel)
    assert_type(events_personnel, EventsPersonnel)
    events_personnel.events_personnel.each do |ep| 
      puts("Updating record for #{ep.date}, #{ep.title}, #{ep.airtable_id}")
      airtable_record = EventTable.find(ep.airtable_id)

      airtable_record[NIGHT_MANAGER_NAME] = ep.night_manager
      airtable_record[VOL_1] = ep.vol1
      airtable_record[VOL_2] = ep.vol2
      airtable_record.save()
    end
  end
end


class Controller

  def initialize()
    @vol_rota_controller = WorkbookController.new(VOL_ROTA_SPREADSHEET_ID)
    @night_manager_controller = WorkbookController.new(NIGHT_MANAGER_SPREADSHEET_ID)
  end

  def vol_tab_controller(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    @vol_rota_controller.add_tab(tab_name) if !@vol_rota_controller.has_tab_with_name?(tab_name)
    VolunteerMonthTabController.new(year, month, @vol_rota_controller)
  end

  def update_vol_sheet_from_airtable(year, month, force)
    tab_controller = vol_tab_controller(year, month)
    airtable_events_personnel = VolunteerAirtableController.read_events_personnel(year, month)
    sheet_events_personnel = tab_controller.read_events_personnel()
    events_personnel = EventsPersonnel.new(
      events_personnel: sheet_events_personnel.events_personnel.collect { |ep|
        if airtable_events_personnel.include?(ep.airtable_id)
          ap = airtable_events_personnel[ep.airtable_id]
          if ep.metadata_match(ap)
            ep
          else
            ep.with_metadata_from(ap)
          end
        else
          ep
        end
      }
    )
    events_personnel = events_personnel.add_missing(airtable_events_personnel)
    if !events_personnel.matches(sheet_events_personnel) || force
      puts("Updating vol sheet")
      tab_controller.replace_events(events_personnel)
    end
  end

  def update_airtable_from_vol_sheet(year, month, force)
    sheet_events = vol_tab_controller(year, month).read_events_personnel()
    if force
      VolunteerAirtableController.update_events_personnel(sheet_events)
    else
      airtable_events = VolunteerAirtableController.read_events_personnel(year, month)
      modified_events = sheet_events.changed_personnel(airtable_events)
      VolunteerAirtableController.update_events_personnel(modified_events)
    end

  end
end


def sync_personnel_data(year, month, force = false)
  controller = Controller.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end


sync_personnel_data(2021, 11, force=false)
