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

class GigMediator
  include GigTableMeta
  def self.from_airtable_record(rec)
    Gig.new(
      airtable_id: rec[ID], 
      gig_no: rec[GIG_NO], 
      vol1: rec[VOL_1],
      vol2: rec[VOL_2],
      night_manager: rec[NIGHT_MANAGER]
    )
  end

end

class GigTakingsMediator
  include GigTableMeta
  def self.from_airtable_record(rec)
    Gig.new(
      airtable_id: rec[ID], 
      gig_no: rec[GIG_NO], 
      online_tickets: rec[ONLINE_TICKETS],
      ticket_price: rec[TICKET_PRICE],
      walk_ins: rec[WALK_INS],
      walk_in_sales: rec[WALK_IN_SALES],
      t_shirts: rec[T_SHIRTS],
      t_shirt_sales: rec[T_SHIRT_SALES],
      mugs: rec[MUGS],
      mug_sales: rec[MUG_SALES]

    )
  end
end

class EventMediator

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


end


