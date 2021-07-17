def assert_dimension_2d(arr, expected_rows, expected_cols)
  raise "Row dimension mismatch, expected #{expected_rows}, got #{arr.size}" if arr.size != expected_rows
  arr.each do |row|
  raise "Col dimension mismatch, expected #{expected_cols}, got #{row.size}" if row.size != expected_cols
  end
end

class SetPersonnel
  def initialize(night_manager, first_volunteer, second_volunteer)
    @night_manager = night_manager
    @first_volunteer = first_volunteer
    @second_volunteer = second_volunteer
  end

  def self.empty
    SetPersonnel.new("", "", "")
  end

  def to_excel_data()
    [@night_manager, @first_volunteer, @second_volunteer]
  end
  def self.from_excel(row)
    raise "Invalid dimension, length #{row.size}, expected 3" if row.size != 3
    SetPersonnel.new(row[0], row[1], row[2])
  end
end

class GigPersonnel
  attr_reader :first_set_volunteer_data, :second_set_volunteer_data, :sound_engineer
  def initialize(first_set_volunteer_data:, second_set_volunteer_data:, sound_engineer:)
    @first_set_volunteer_data = first_set_volunteer_data
    @second_set_volunteer_data = second_set_volunteer_data
    @sound_engineer = sound_engineer
  end

  def self.empty
    GigPersonnel.new(
      first_set_volunteer_data: SetPersonnel.empty, 
      second_set_volunteer_data: SetPersonnel.empty, 
      sound_engineer: ""
    )
  end

  def to_excel_data()
    [
      @first_set_volunteer_data.to_excel_data() + [@sound_engineer],
      @second_set_volunteer_data.to_excel_data() + [""]
    ]
  end

  def self.from_excel(rows)
    assert_dimension_2d(rows, 2, 4)
    sound_engineer = rows[0][3]
    first_set_volunteers = SetPersonnel.from_excel(rows[0].slice(0, 3))
    second_set_volunteers = SetPersonnel.from_excel(rows[1].slice(0, 3))
    GigPersonnel.new(
      first_set_volunteer_data: first_set_volunteers, 
      second_set_volunteer_data: second_set_volunteers,
      sound_engineer: sound_engineer
    )
  end
end

class VolunteerSheetDetailsForEvent
  attr_reader :event_date
  def initialize(event_date, event_title, personnel)
    @event_date = event_date
    @event_title = event_title
    @personnel = personnel
  end

  def to_excel_data()
    [
      [@event_title, @event_date, @event_date, 1, "19:00"] + @personnel.first_set_volunteer_data.to_excel_data() + [@personnel.sound_engineer],
      ["", "", "", 2, "21:00"] + @personnel.second_set_volunteer_data.to_excel_data() + [""]
    ]
  end

  def self.from_airtable_record(record)
    VolunteerSheetDetailsForEvent.new(record.event_date, record.event_title, GigPersonnel.empty)
  end

  def self.from_excel(rows)
    assert_dimension_2d(rows, 2, 9)
    event_date = Date.parse(rows[0][1])
    event_title = rows[0][0]
    personnel = GigPersonnel.from_excel(
      [
        rows[0].slice(5, 4),
        rows[1].slice(5, 4)
      ]
    )
    VolunteerSheetDetailsForEvent.new(
      event_date, event_title, personnel
    )
  end

end

class VolunteerSheetDetailsForMonth
  def initialize(event_details)
    @event_details = event_details
    @events_by_date = Hash[ *event_details.collect { |e| [e.event_date, e ] }.flatten ]
  end

  def num_events
    @event_details.size
  end
  def sorted()
    @event_details.sort_by { |a| a.event_date}
  end

  def add_missing_airtable_events(airtable_events)
    merged_events = [*@event_details]
    airtable_events.events.each do |airtable_event|
      if !@events_by_date.has_key?(airtable_event.event_date)
        merged_events.push(
          VolunteerSheetDetailsForEvent.from_airtable_record(airtable_event)
        )
      end
    end
    VolunteerSheetDetailsForMonth.new(merged_events)
  end
end
