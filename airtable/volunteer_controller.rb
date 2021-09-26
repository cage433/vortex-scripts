require_relative 'contract_table'
require 'time'

class VolunteerAirtableController

  def self.door_time(rec)
    if rec[DOORS_TIME].nil?
      ""
    else
      Time.parse(rec[DOORS_TIME]).strftime("%H:%M")
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
  def self.read_personnels_by_date(year, month)
    include EventTableMeta
    event_ids = EventTable.ids_for_month(year, month)
    event_records = EventTable.find_many(event_ids)
    personnels_by_date = event_records.group_by { |rec| rec[EVENT_DATE] }.collect { |date, records_for_date|
      events_personnel = records_for_date.collect { |rec|
        EventPersonnel.new(
          airtable_id: rec[ID], 
          title: self._event_title(rec),
          date: rec[EVENT_DATE],
          doors_open: self.door_time(rec),
          vol1: rec[VOL_1],
          vol2: rec[VOL_2],
          night_manager: rec[NIGHT_MANAGER],
          sound_engineer: rec[SOUND_ENGINEER],
        )
      }
      PersonnelForDate.new(events_personnel: events_personnel)
    }
    DatedCollection.new(personnels_by_date)
    

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
