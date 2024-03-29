require_relative '../env'
require_relative '../utils/utils'
require_relative 'vortex_table'
require 'airrecord'

Airrecord.api_key = AIRTABLE_API_KEY 

module ContractsColumns
  TABLE = "Contracts"

  CODE = "Code"
  RECORD_ID = "Record ID"
  EVENT_TITLE = "Event title"
  EVENTS_LINK = "Events Link"
  ORGANISERS = "Organisers"
  TYPE = "Type"
  STATUS = "Status"
  LIVE_PAYABLE = "Live Payable"
  VORTEX_PROFIT = "Vortex Profit"
  HIRE_FEE = "Hire fee"
  FOOD_BUDGET = "Food budget"
  COS_REQUIRED = "COS required"
  TOTAL_TICKET_SALES_CALC = "Total Ticket Sales £ calc"
  PERFORMANCE_DATE = "Performance date"

  B_ONLINE = "B - Online"
  C_CARD = "C - Card"
  D_CASH = "D - Cash"
  E_STUDENTS = "E - Students"
  N_CREDIT_CARD_TAKINGS = "N - Credit card takings"
  DEDUCTIONS = "Deductions"
  TOTAL_AUDIENCE = "Total audience"
  HOTEL = "Hotel?"
  HOTELS_COST = "Hotels cost"
  TRANSPORT = "Transport"
  TRANSPORT_COST = "Transport Cost"
  AUDIENCE_FOOD_COST = "Audience Food Cost "
  PRS_PAYABLE = "PRS?"
  PAID = "Paid?"
  NIGHT_MANAGER = "Night Manager"
  GRANTS = "Grants"

  FULL_TICKET_PRICE = "Full ticket price"
  MEMBER_TICKET_PRICE = "Member ticket price"
  STUDENT_TICKET_PRICE = "Student ticket price"
  MUSICIANS_FEE = "Musicians fee"

end

class Contracts < Airrecord::Table

  include ContractsColumns

  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  STREAMING_PRS_FEE = 22
  PRS_RATE = 0.04

  def self._select(fields:, first_date:, last_date:)
    select_with_date_filter(
      table: TABLE,
      fields: fields,
      date_field: PERFORMANCE_DATE,
      first_date: first_date,
      last_date: last_date,
    )
  end

  def self.ids_for_date_range(date_range:)
    _select(
      fields: [RECORD_ID],
      first_date: date_range.first_date,
      last_date: date_range.last_date
    ).collect { |rec| rec[RECORD_ID] }
  end

  def gig_type
    fields[TYPE]
  end

  def is_streaming?
    gig_type == "Live Stream"
  end

  def is_prs_payable?
    is_payable = fields[PRS_PAYABLE]
    if is_payable.nil?
      true
    else
      is_payable
    end
  end

  def performance_date
    Date.parse(fields[PERFORMANCE_DATE])
  end

  def hire_fee
    fields[HIRE_FEE] || 0
  end

  def full_ticket_price
    fields[FULL_TICKET_PRICE]
  end

  def member_ticket_price
    fields[MEMBER_TICKET_PRICE]
  end

  def student_ticket_price
    fields[STUDENT_TICKET_PRICE]
  end

  def musicians_fee
    fields[MUSICIANS_FEE] || 0
  end

  def accommodation_costs
    fields[HOTELS_COST] || 0
  end

  def travel_expenses
    fields[TRANSPORT_COST] || 0
  end

  def food_budget
    fields[FOOD_BUDGET] || 0
  end

end
