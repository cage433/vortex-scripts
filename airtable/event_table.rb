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
  VOL_3 = "Vol 3 Name"
  STATUS = "Status"
  MEMBER_BOOKINGS = "Member Bookings"
  NM_NOTES = "NM Notes"
  FULL_PRICE_TICKETS_ONLINE = "Full price tickets (online)"
  FULL_PRICE_TICKETS_WALK_IN = "Full price tickets (walk-in)"
  FULL_PRICE_SALES = "Full price sales"
  MEMBER_TICKETS_ONLINE = "Member tickets (online)"
  MEMBER_TICKETS_WALK_IN = "Member tickets (walk-in)"
  STUDENT_TICKETS_ONLINE = "Student tickets (online)"
  STUDENT_TICKETS_WALK_IN = "Student tickets (walk-in)"
  STUDENT_SALES = "Student sales"
  PROMO_TICKETS = "Promo tickets (free)"
  MEMBER_PRICE = "Member ticket price"
  MEMBER_SALES = "Member sales"
  STUDENT_PRICE = "Student ticket price"
  TOTAL_TICKET_SALES = "Total ticket sales"
  OTHER_TICKETS_WALK_IN = "Other tickets (walk-in)"
  OTHER_TICKET_SALES = "Other ticket sales"
  CREDIT_CARD_TAKINGS = "Bar takings"
  EVENING_PURCHASES = "Evening purchases"
  CONTRACT_TYPE = "Contract Type"
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

  def full_price_tickets
    (fields[FULL_PRICE_TICKETS_ONLINE] || 0) + (fields[FULL_PRICE_TICKETS_WALK_IN] || 0)
  end

  def member_tickets
    (fields[MEMBER_TICKETS_ONLINE] || 0) + (fields[MEMBER_TICKETS_WALK_IN] || 0)
  end

  def student_tickets
    (fields[STUDENT_TICKETS_ONLINE] || 0) + (fields[STUDENT_TICKETS_WALK_IN] || 0)
  end

  def other_tickets
    fields[OTHER_TICKETS_WALK_IN] || 0
  end

  def promo_tickets
    fields[PROMO_TICKETS] || 0
  end

  def other_ticket_sales
    fields[OTHER_TICKET_SALES] || 0
  end

  def full_price_sales
    fields[FULL_PRICE_SALES] || 0
  end

  def member_sales
    fields[MEMBER_SALES] || 0
  end

  def student_sales
    fields[STUDENT_SALES] || 0
  end

  def total_ticket_sales
    fields[TOTAL_TICKET_SALES] || 0
  end

  def credit_card_takings
    fields[CREDIT_CARD_TAKINGS] || 0
  end

  def door_time
    fields[DOORS_TIME]
  end

  def evening_purchases
    fields[EVENING_PURCHASES] || 0
  end

end


