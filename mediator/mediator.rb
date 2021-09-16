require_relative '../model/model'
require_relative '../airtable/fields'

require 'date'

def assert_dimension_2d(arr, expected_rows, expected_cols)
  raise "Row dimension mismatch, expected #{expected_rows}, got #{arr.size}" if arr.size != expected_rows
  arr.each do |row|
  raise "Col dimension mismatch, expected #{expected_cols}, got #{row.size}" if row.size != expected_cols
  end
end


class SetPersonnelMediator
  def self.to_excel_data(personnel)
    [personnel.night_manager, personnel.first_volunteer, personnel.second_volunteer]
  end

  def self.from_excel(row)
    raise "Invalid dimension, length #{row.size}, expected 3" if row.size != 3
    SetPersonnel.new(row[0], row[1], row[2])
  end
end


class GigPersonnelMediator
  def self.to_excel_data(gig_personnel)
    [
      gig_personnel.first_set_volunteer_data.to_excel_data() + [gig_personnel.sound_engineer],
      gig_personnel.second_set_volunteer_data.to_excel_data() + [""]
    ]
  end

  def self.from_excel(rows)
    assert_dimension_2d(rows, 2, 4)
    sound_engineer = rows[0][3]
    first_set_volunteers = SetPersonnelMediator.from_excel(rows[0].slice(0, 3))
    second_set_volunteers = SetPersonnelMediator.from_excel(rows[1].slice(0, 3))
    GigPersonnel.new(
      first_set_volunteer_data: first_set_volunteers, 
      second_set_volunteer_data: second_set_volunteers,
      sound_engineer: sound_engineer
    )
  end
end

class EventMediator
  def self.to_excel_data(event)
    [
      [event.event_title, event.event_date, event.event_date, 1, "19:00"] + 
        SetPersonnelMediator.to_excel_data(event.personnel.first_set_volunteer_data) + 
        [event.personnel.sound_engineer],
      ["", "", "", 2, "21:00"] + 
      SetPersonnelMediator.to_excel_data(event.personnel.second_set_volunteer_data) + [""]
    ]
  end

  def self.from_airtable_record(record)
    record_id = record.id
    event_date = Date.parse(record[ALEX_EVENT_DATE])
    event_title = record[ALEX_EVENT_TITLE]
    Event.new(event_date, event_title, GigPersonnel.empty)
  end

  def self.from_excel(rows)
    assert_dimension_2d(rows, 2, 9)
    event_date = Date.parse(rows[0][1])
    event_title = rows[0][0]
    personnel = GigPersonnelMediator.from_excel(
      [
        rows[0].slice(5, 4),
        rows[1].slice(5, 4)
      ]
    )
    Event.new(
      event_date, event_title, personnel
    )
  end
end

