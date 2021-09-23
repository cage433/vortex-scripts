require_relative '../model/model'
require_relative 'gig_table.rb'

class NightManagerAirtableController

  def self.read_events(event_ids)
    include ContractTableMeta
    include GigTableMeta

    def self.gig_takings_from_record(rec)
      GigTakings.new(
        airtable_id: rec[ID], 
        gig_no: rec[GIG_NO],
        online_tickets: rec[ONLINE_TICKETS], ticket_price: rec[TICKET_PRICE],
        walk_ins: rec[WALK_INS], walk_in_sales: rec[WALK_IN_SALES], 
        guests_or_cheap: rec[GUESTS_OR_CHEAP], guest_or_cheap_sales: rec[GUEST_OR_CHEAP_SALES], 
        t_shirts:rec[T_SHIRTS], t_shirt_sales: rec[T_SHIRT_SALES], 
        mugs: rec[MUGS], mug_sales: rec[MUG_SALES]
      )
    end
    event_records = ContractTable.find_many(event_ids)

    gig_ids = event_records.collect { |rec| rec[GIG_IDS] }.flatten
    gigs_by_id = Hash[ 
      GigTable
      .find_many(gig_ids)
      .collect { |rec| 
        [rec[ID], gig_takings_from_record(rec)] 
      } 
    ]
    event_records.collect { |event_record|
      gig1, gig2 = event_record[GIG_IDS].collect { |id| gigs_by_id[id] }.sort_by{ |g| g.gig_no }
      date = Date.parse(event_record[DATE])
      title = event_record[TITLE]
      NightManagerEvent.new(
        airtable_id: event_record[ID],
        date: date,
        title: event_record[TITLE],
        fee_details: FeeDetails.new(
          fee_notes: event_record[FEE_NOTES],
          flat_fee: event_record[FLAT_FEE],
          minimum_fee: event_record[MIN_FEE],
          fee_percentage: event_record[FEE_PERCENTAGE]
        ),
        gig1_takings: gig1, gig2_takings: gig2,
      )
    }

  end

  def self.read_events_for_month(year, month)
    EventsCollection.new(
      self.read_events(ContractTable.ids_for_month(year, month))
    )
  end

  def self.update_events(events)
    events.each do |event| 
      puts("Updating record for #{event.date}, #{event.title}, #{event.airtable_id}")

      [event.gig1_takings, event.gig2_takings].each do |gig|
        # Note that we don't update ticket price, as airtable is the source of truth for that

        gig_record = GigTable.find(gig.airtable_id)

        gig_record[ONLINE_TICKETS] = gig.online_tickets
        gig_record[WALK_INS] = gig.walk_ins
        gig_record[WALK_IN_SALES] = gig.walk_in_sales
        gig_record[GUESTS_OR_CHEAP] = gig.guests_or_cheap
        gig_record[GUEST_OR_CHEAP_SALES] = gig.guest_or_cheap_sales
        gig_record[T_SHIRTS] = gig.t_shirts
        gig_record[T_SHIRT_SALES] = gig.t_shirt_sales
        gig_record[MUGS] = gig.mugs
        gig_record[MUG_SALES] = gig.mug_sales

        gig_record.save
      end
    end
  end
end
