require_relative '../model/model'
require_relative '../airtable/event_table'
require_relative '../airtable/gig_table'

require 'date'

def assert_dimension_2d(arr, expected_rows, expected_cols)
  raise "Row dimension mismatch, expected #{expected_rows}, got #{arr.size}" if arr.size != expected_rows
  arr.each do |row|
  raise "Col dimension mismatch, expected #{expected_cols}, got #{row.size}" if row.size != expected_cols
  end
end

module VolunteerRotaColumns
  EVENT_ID_COL, GIG_ID_COL, TITLE_COL, DATE_COL, DAY_COL, 
    GIG_NO_COL, DOORS_OPEN_COL, NIGHT_MANAGER_COL, 
    VOL_1_COL, VOL_2_COL, SOUND_ENGINEER_COL = [*0..10]
end

class GigMediator
  include GigTableMeta
  include VolunteerRotaColumns
  def self.from_airtable_record(rec)
    Gig.new(
      airtable_id: rec[ID], 
      gig_no: rec[GIG_NO], 
      vol1: rec[VOL_1],
      vol2: rec[VOL_2],
      night_manager: rec[NIGHT_MANAGER]
    )
  end

  def self.from_excel(row)
    Gig.new(
      airtable_id: row[GIG_ID_COL],
      gig_no: row[GIG_NO_COL],
      vol1: row[VOL_1_COL],
      vol2: row[VOL_2_COL],
      night_manager: row[NIGHT_MANAGER_COL]
    )
  end
end

class EventMediator
  include VolunteerRotaColumns
  def self.to_excel_data(event)
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
    [row1, row2]
  end

  def self.to_night_manager_xl_data(event, i_event)
      i_row = 1 + i_event * 3
      first_row = [
        event.airtable_id, 
        event.gig1.airtable_id, 
        event.event_title, 
        event.event_date, 
        event.event_date,
        1, "19:00",
        "", "", "", "", 
        "=Sum(I#{i_row}:J#{i_row})", 
        "",
        "", "", "", "", "", "", "", 
      ] 
      second_row = [
        "",
        event.gig2.airtable_id, 
        "", "", "",
        2, "21:00",
        "", "", "", "", "", "", 
        "", "", "", "", "", "", "", 
      ]
      blank_row = [""] * 20
      [first_row, second_row, blank_row]
  end

  def self.from_airtable_many(event_ids)
    include EventTableMeta
    event_records = EventTable.find_many(event_ids)

    gig_ids = event_records.collect { |rec| rec[GIG_IDS] }.flatten
    gigs_by_id = Hash[ 
      GigTable
      .find_many(gig_ids)
      .collect { |rec| 
        [rec[ID], GigMediator.from_airtable_record(rec)] 
      } 
    ]
    event_records.collect { |event_record|
      gig1, gig2 = event_record[GIG_IDS].collect { |id| gigs_by_id[id] }.sort_by{ |g| g.gig_no }
      event_date = Date.parse(event_record[DATE])
      event_title = event_record[TITLE]
      Event.new(
        airtable_id: event_record[ID],
        event_date: event_date,
        event_title: event_record[TITLE],
        gig1: gig1, gig2: gig2,
        sound_engineer: event_record[SOUND_ENGINEER]
      )
    }

  end

  def self.from_excel(rows)
    assert_dimension_2d(rows, 2, 11)
    event_id = rows[0][EVENT_ID_COL]
    gig1 = GigMediator.from_excel(rows[0])
    gig2 = GigMediator.from_excel(rows[1])
    event_date = Date.parse(rows[0][DATE_COL])
    event_title = rows[0][TITLE_COL]
    sound_engineer = rows[0][SOUND_ENGINEER_COL]
    Event.new(
      airtable_id: event_id,
      event_date: event_date,
      event_title: event_title,
      gig1: gig1, gig2: gig2,
      sound_engineer: sound_engineer
    )
  end

end


