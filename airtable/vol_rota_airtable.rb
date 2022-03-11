require 'airrecord'
require_relative 'vortex_table'
require_relative 'event_table'
require_relative '../env'
require_relative '../logging'
require_relative '../utils/utils'
require_relative '../model/event_personnel'



######################
#     Airtable
#######################

Airrecord.api_key = AIRTABLE_API_KEY 


module ContactsTableMeta
  ID = "Record ID"
  ROLE = "Role"
  TABLE = "Contacts"
  FULL_NAME = "Full Name"
end

class ContactsTable < Airrecord::Table
  include ContactsTableMeta
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

end

class SoundEngineers
  include ContactsTableMeta
  def initialize()
    recs = ContactsTable.all(
      fields:[ID, FULL_NAME],
      filter: "{#{ROLE}} = 'Sound Engineer'"
    )
    @engineers_by_id = Hash[ *recs.collect { |rec| [rec[ID], rec[FULL_NAME]]}.flatten ]
  end

  def [](id)
    @engineers_by_id[id]
  end
end

class VolunteerAirtableController
  include EventTableColumns

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
        sound_engineer: sound_engineer,
        member_bookings: rec[MEMBER_BOOKINGS],
        nm_notes: rec[NM_NOTES]
      )
    }
    EventsPersonnel.new(events_personnel: events_personnel)

  end


  def self.update_events_personnel(events_personnel)
    assert_type(events_personnel, EventsPersonnel)
    events_personnel.events_personnel.each do |ep| 
      VOL_ROTA_LOGGER.info("Updating record for #{ep.date}, #{ep.title}, #{ep.airtable_id}")
      airtable_record = EventTable.find(ep.airtable_id)

      airtable_record[NIGHT_MANAGER_NAME] = ep.night_manager
      airtable_record[VOL_1] = ep.vol1
      airtable_record[VOL_2] = ep.vol2
      airtable_record[MEMBER_BOOKINGS] = ep.member_bookings
      airtable_record[NM_NOTES] = ep.nm_notes
      airtable_record.save()
    end
  end
end
