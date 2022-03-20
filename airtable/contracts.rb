require_relative '../env'
require_relative '../utils/utils'
require_relative 'vortex_table'
require 'airrecord'

Airrecord.api_key = AIRTABLE_API_KEY 

module ContractsColumns
  TABLE = "Contracts"

  CODE = "Code"
  EVENT_TITLE = "Event title"
  ORGANISERS = "Organisers"
  TYPE = "Type"
  STATUS = "Status"
  AGREEMENT_TEXT_FORMLA = "Agreement text formula"
  PERCENTAGE_SPLIT_TO_ARTIST = "Percentage split to Artist"
  FLAT_FEE_TO_ARTIST = "Flat Fee to Artist"
  VS_FEE = "VS fee?"
  IS_PERCENTAGE_GTR_THAN_FEE = "Is % Greater than Fee?"
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
  PRS = "PRS?"
  PAID = "Paid?"
  NIGHT_MANAGER = "Night Manager"
  GRANTS = "Grants"
end

class Contracts < Airrecord::Table

  include ContractsColumns
   
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  def self._select(fields:, first_date:, last_date:)
    select_with_date_filter(
      table: TABLE,
      fields: fields,
      date_field: PERFORMANCE_DATE,
      first_date: first_date,
      last_date: last_date,
    )
  end

  def self.titles_for_month(year, month_no)
    _select(
      fields: [PERFORMANCE_DATE, EVENT_TITLE],
      first_date: Date.new(year, month_no, 1),
      last_date: Date.new(year, month_no, -1)
    ).collect { |rec| [rec[PERFORMANCE_DATE], rec[EVENT_TITLE]] }
  end
end
