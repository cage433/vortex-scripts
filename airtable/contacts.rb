require 'airrecord'
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
