require_relative '../env'
require_relative '../utils/utils'
require_relative 'vortex_table'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module EventTableColumns
  TABLE = "Events"

  EVENT_ID = "Record ID"
  EVENT_TITLE_FROM_CONTRACT = "Event Title (from contract)"
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
  STANDARD_TICKET_VALUE_HISTORIC = "B Advance Online&credit card tickets (historic)"
  MEMBER_PRICE = "Ca ticket price (if different)"
  STUDENT_PRICE = "E - Student ticket price"
  STUDENT_TICKETS_SOLD = "E - Student tickets sold"
  CASH_TICKET_VALUE = "D Cash or Live Stream tickets"
  ZETTLE_READING = "N Credit card Takings - Polling report total"
  HIRE_FEE = "Hire Fee"
  F1_HIRE_FEE_CASH = "F1 Hire fee cash"
  F2_HIRE_FEE_BACS = "F2 Hire fee cheque or BACS"

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

  def b_tickets_sold
    fields[B_TICKETS] || 0
  end

  def member_tickets_sold
    fields[C_TICKETS] || 0
  end

  def member_ticket_price_or_nil
    fields[MEMBER_PRICE]
  end

  def member_ticket_value(standard_ticket_price)
    member_ticket_price = fields[MEMBER_PRICE] || standard_ticket_price
    member_tickets_sold * member_ticket_price
  end

  def student_tickets_sold
    fields[STUDENT_TICKETS_SOLD] || 0

  end

  def student_ticket_price
    fields[STUDENT_PRICE] || 0
  end

  def student_ticket_value
    student_tickets_sold * student_ticket_price
  end

  def cash_ticket_value
    fields[CASH_TICKET_VALUE] || 0
  end

  def zettle_reading
    fields[ZETTLE_READING] || 0
  end

  def total_hire_fee
    hire_fee = fields[HIRE_FEE] || 0
    f1_hire_fee = fields[F1_HIRE_FEE_CASH] || 0
    f2_hire_fee = fields[F2_HIRE_FEE_BACS] || 0
    hire_fee + f1_hire_fee + f2_hire_fee
  end

  def event_title_from_contract
    fields[EVENT_TITLE_FROM_CONTRACT] || ""
  end

end


