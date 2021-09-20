require_relative 'event_table'

class VolunteerAirtableController

  def self.read_events(event_ids)
    include EventTableMeta
    include GigTableMeta

    def self.gig_from_record(rec)
      Gig.new(
        airtable_id: rec[ID], 
        gig_no: rec[GIG_NO], 
        vol1: rec[VOL_1],
        vol2: rec[VOL_2],
        night_manager: rec[NIGHT_MANAGER]
      )
    end
    event_records = EventTable.find_many(event_ids)

    gig_ids = event_records.collect { |rec| rec[GIG_IDS] }.flatten
    gigs_by_id = Hash[ 
      GigTable
      .find_many(gig_ids)
      .collect { |rec| 
        [rec[ID], gig_from_record(rec)] 
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

  def self.read_events_for_month(year, month)
    EventsForMonth.new(
      year, month,
      self.read_events(EventTable.ids_for_month(year, month))
    )
  end
end
