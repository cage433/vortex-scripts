require_relative '../env'
require_relative '../utils/utils'
require_relative 'vortex_table'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module EventTableColumns
  TABLE = "Events"

  EVENT_ID = "Record ID"
  SHEETS_EVENT_TITLE = "SheetsEventTitle"
  EVENT_DATE = "Event Date"
  DOORS_TIME = "Doors Time"
  SOUND_ENGINEER = "Sound Engineer"
  NIGHT_MANAGER_NAME = "Night Manager Name"
  VOL_1 = "Vol 1 Name"
  VOL_2 = "Vol 2 Name"
  STATUS = "Status"
  MEMBER_BOOKINGS = "Member Bookings"
  NM_NOTES = "NM Notes"
  BA_TICKETS = "Ba Tickets sold - card advance"
  B_TICKETS = "B Tickets sold - Advance Online & credit card"
  C_TICKETS = "C Tickets sold - card door"
  D_TICKETS = "D Tickets sold - cash"
  E_TICKETS = "E - Student tickets sold"
  PROMO_TICKETS = "Promo tickets (free)"
end

class EventTable < Airrecord::Table

  include EventTableColumns
   
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  def self._select(fields:, first_date:, last_date:)
    select_with_date_filter(
      table: EventTable,
      fields: fields,
      date_field: EVENT_DATE,
      first_date: first_date,
      last_date: last_date,
      extra_filters: ["{#{STATUS}} = 'Confirmed'"]
    )
  end

  def self.ids_for_month(year, month_no)
    _select(
      fields: [EVENT_ID],
      first_date: Date.new(year, month_no, 1),
      last_date: Date.new(year, month_no, -1)
    ).collect { |rec| rec[EVENT_ID] }
  end


  def self.event_titles_for_date(date)
    # Could be more than 1, e.g. late night Saturday gigs
    recs = _select(
      fields: [SHEETS_EVENT_TITLE],
      first_date: date,
      last_date: date
    )
    recs.collect { |rec| rec[SHEETS_EVENT_TITLE] }.flatten.uniq
  end
  

end


