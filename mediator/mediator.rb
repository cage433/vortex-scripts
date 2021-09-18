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


#class SetPersonnelMediator
  #def self.to_excel_data(personnel)
    #[personnel.night_manager, personnel.first_volunteer, personnel.second_volunteer]
  #end

  #def self.from_excel(row)
    #raise "Invalid dimension, length #{row.size}, expected 3" if row.size != 3
    #SetPersonnel.new(row[0], row[1], row[2])
  #end

  #def self.from_airtable_record(rec)
    #SetPersonnel.new(
      #rec[ALEX_NIGHT_MANAGER], rec[ALEX_VOL_1], rec[ALEX_VOL_2]
    #)
  #end
#end


#class GigPersonnelMediator
  #def self.to_excel_data(gig_personnel)
    #[
      #gig_personnel.first_set_volunteer_data.to_excel_data() + [gig_personnel.sound_engineer],
      #gig_personnel.second_set_volunteer_data.to_excel_data() + [""]
    #]
  #end

  #def self.from_excel(rows)
    #assert_dimension_2d(rows, 2, 4)
    #sound_engineer = rows[0][3]
    #first_set_volunteers = SetPersonnelMediator.from_excel(rows[0].slice(0, 3))
    #second_set_volunteers = SetPersonnelMediator.from_excel(rows[1].slice(0, 3))
    #GigPersonnel.new(
      #first_set_volunteer_data: first_set_volunteers, 
      #second_set_volunteer_data: second_set_volunteers,
      #sound_engineer: sound_engineer
    #)
  #end

#end

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

  def self.from_airtable(event_id)
    include EventTableMeta
    event_record = EventTable.find(event_id)
    gig_ids = event_record[GIG_IDS]
    gig1, gig2 = GigTable
      .find_many(gig_ids)
      .collect { |rec| GigMediator.from_airtable_record(rec) }
      .sort_by { |g| g.gig_no }
    event_date = Date.parse(event_record[DATE])
    event_title = event_record[TITLE]
    Event.new(
      airtable_id: event_id,
      event_date: event_date,
      event_title: event_record[TITLE],
      gig1: gig1, gig2: gig2,
      sound_engineer: event_record[SOUND_ENGINEER]
    )
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


