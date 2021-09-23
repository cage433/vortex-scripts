require_relative 'contract_table'

class VolunteerAirtableController

  def self.read_events(event_ids)
    include EventTableMeta
    include GigTableMeta

    def self.gig_from_record(rec)
      GigPersonnel.new(
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
      date = Date.parse(event_record[DATE])
      title = event_record[TITLE]
      Event.new(
        airtable_id: event_record[ID],
        date: date,
        title: event_record[TITLE],
        gig1: gig1, gig2: gig2,
        sound_engineer: event_record[SOUND_ENGINEER]
      )
    }

  end

  def self.read_events_for_month(year, month)
    DatedCollection.new(
      self.read_events(EventTable.ids_for_month(year, month))
    )
  end

  def self.update_events(events)
    events.each do |event| 
      puts("Updating record for #{event.date}, #{event.title}, #{event.airtable_id}")
      airtable_record = EventTable.find(event.airtable_id)
      airtable_record[SOUND_ENGINEER] = event.sound_engineer
      airtable_record.save()

      [event.gig1, event.gig2].each do |gig|
        gig_record = GigTable.find(gig.airtable_id)
        gig_record[NIGHT_MANAGER] = gig.night_manager
        gig_record[VOL_1] = gig.vol1
        gig_record[VOL_2] = gig.vol2
        gig_record.save
      end
    end
  end
end
