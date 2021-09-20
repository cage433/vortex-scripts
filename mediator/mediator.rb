require_relative '../model/model'
require_relative '../airtable/event_table'
require_relative '../airtable/gig_table'

require 'date'


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


end


