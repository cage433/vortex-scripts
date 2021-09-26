require_relative 'contract_table'
require_relative 'contacts'
require 'time'

class VolunteerAirtableController
  include EventTableMeta

  def self.door_time(rec)
    if rec[DOORS_TIME].nil?
      nil
    else
      Time.parse(rec[DOORS_TIME])
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

  def self.read_events_personnel(year, month)
    event_ids = EventTable.ids_for_month(year, month)
    event_records = EventTable.find_many(event_ids)
    sound_engineers = SoundEngineers.new()
    events_personnel = event_records.collect { |rec|
      sound_engineer = if is_nil_or_blank?(rec[SOUND_ENGINEER]) then
                         nil
                       else
                         sound_engineers[rec[SOUND_ENGINEER][0]]
                       end

      EventPersonnel.new(
        airtable_id: rec[ID], 
        title: self._event_title(rec),
        date: Date.parse(rec[EVENT_DATE]),
        doors_open: self.door_time(rec),
        vol1: rec[VOL_1],
        vol2: rec[VOL_2],
        night_manager: rec[NIGHT_MANAGER_NAME],
        sound_engineer: sound_engineer
      )
    }
    EventsPersonnel.new(events_personnel: events_personnel)

  end


  def self.update_events_personnel(events_personnel)
    assert_type(events_personnel, EventsPersonnel)
    events_personnel.events_personnel.each do |ep| 
      puts("Updating record for #{ep.date}, #{ep.title}, #{ep.airtable_id}")
      airtable_record = EventTable.find(ep.airtable_id)

      airtable_record[NIGHT_MANAGER_NAME] = ep.night_manager
      airtable_record[VOL_1] = ep.vol1
      airtable_record[VOL_2] = ep.vol2
      airtable_record.save()
    end
  end
end
