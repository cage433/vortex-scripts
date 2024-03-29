require_relative 'contracts'
require_relative 'event_table'
require_relative '../date_range/date_range'
include ContractsColumns
include EventTableColumns

class ContractAndEvents
  attr_reader :contract, :events
  def initialize(contract:, events:)
    @contract = contract
    @events = events
  end

  def full_price_tickets
    @events.collect{|e| e.full_price_tickets}.sum
  end

  def member_tickets
    @events.collect{|e| e.member_tickets}.sum
  end

  def student_tickets
    @events.collect{|e| e.student_tickets}.sum
  end

  def other_tickets
    @events.collect{|e| e.other_tickets}.sum
  end

  def promo_tickets
    @events.collect{|e| e.promo_tickets}.sum
  end

  def hire_fee
    @contract.hire_fee
  end


  def total_ticket_count
    full_price_tickets + member_tickets + student_tickets + other_tickets + promo_tickets
  end

  def event_name
    @contract[EVENT_TITLE]
  end

  def standard_ticket_price
    @contract[FULL_TICKET_PRICE] || 0
  end

  def full_price_sales
    @events.collect{|e| e.full_price_sales}.sum
  end

  def member_sales
    @events.collect{|e| e.member_sales}.sum
  end

  def student_sales
    @events.collect{|e| e.student_sales}.sum

  end

  def other_ticket_sales
    @events.collect{|e| e.other_ticket_sales}.sum
  end

  def total_ticket_sales
    full_price_sales + member_sales + student_sales + other_ticket_sales
  end

  def credit_card_takings
    @events.collect{|e| e.credit_card_takings}.sum
  end

  def musicians_fee
    @contract.musicians_fee
  end

  def accommodation_costs
    @contract.accommodation_costs
  end

  def travel_expenses
    @contract.travel_expenses
  end

  def food_budget
    @contract.food_budget
  end

  def evening_purchases
    @events.collect{|e| e.evening_purchases}.sum
  end

  def prs_fee
    if @contract.is_prs_payable?
      if @contract.is_streaming?
        Contracts::STREAMING_PRS_FEE
      else
        total_ticket_sales * Contracts::PRS_RATE
      end
    else
      0
    end
  end

  def performance_date
    @contract.performance_date
  end
end

class MultipleContractsAndEvents
  attr_reader :contracts_and_events

  VAT_RATE = 1.2

  def initialize(contracts_and_events:)
    @contracts_and_events = contracts_and_events
  end

  def length
    @contracts_and_events.length
  end

  def filter(fn)
    MultipleContractsAndEvents.new(
      contracts_and_events: @contracts_and_events.select { |ce| fn.call(ce) }
    )
  end

  def total_ticket_count
    @contracts_and_events.collect { |ce| ce.total_ticket_count }.sum
  end

  def total_full_price_tickets
    @contracts_and_events.collect { |ce| ce.full_price_tickets }.sum
  end

  def total_member_tickets
    @contracts_and_events.collect { |ce| ce.member_tickets }.sum
  end

  def total_student_tickets
    @contracts_and_events.collect { |ce| ce.student_tickets }.sum
  end

  def total_other_tickets
    @contracts_and_events.collect { |ce| ce.other_tickets }.sum
  end

  def total_guest_tickets
    @contracts_and_events.collect { |ce| ce.promo_tickets }.sum
  end

  def total_ticket_sales
    @contracts_and_events.collect { |ce| ce.total_ticket_sales }.sum
  end

  def total_student_sales
    @contracts_and_events.collect { |ce| ce.student_sales }.sum
  end

  def total_full_price_sales
    @contracts_and_events.collect { |ce| ce.full_price_sales }.sum
  end

  def total_member_sales
    @contracts_and_events.collect { |ce| ce.member_sales }.sum
  end

  def total_other_ticket_sales
    @contracts_and_events.collect { |ce| ce.other_ticket_sales }.sum
  end

  def total_prs_fee_ex_vat
    @contracts_and_events.collect { |ce| ce.prs_fee }.sum / VAT_RATE
  end

  def total_hire_fee
    @contracts_and_events.collect { |ce| ce.hire_fee }.sum
  end

  def total_zettle_reading
    @contracts_and_events.collect { |ce| ce.credit_card_takings }.sum
  end

  def total_musicians_fees
    @contracts_and_events.collect { |ce| ce.musicians_fee }.sum
  end

  def total_accommodation_costs
    @contracts_and_events.collect { |ce| ce.accommodation_costs }.sum
  end

  def total_travel_expenses
    @contracts_and_events.collect { |ce| ce.travel_expenses }.sum
  end

  def total_food_budget
    @contracts_and_events.collect { |ce| ce.food_budget }.sum
  end

  def total_musician_costs
    total_musicians_fees + total_accommodation_costs + total_travel_expenses + total_food_budget
  end

  def total_prs_fee
    @contracts_and_events.collect { |ce| ce.prs_fee }.sum
  end

  def total_evening_purchases
    @contracts_and_events.collect { |ce| ce.evening_purchases }.sum
  end

  def restrict_to_period(period)
    MultipleContractsAndEvents.new(
      contracts_and_events: @contracts_and_events.select { |ce| period.contains?(ce.contract.performance_date) }
    )
  end

  def self.read_many(date_range: nil)

    contract_ids = Contracts.ids_for_date_range(date_range: date_range)
    contract_records = Contracts.find_many(contract_ids)
    event_ids = contract_records.collect {|rec|
      rec[EVENTS_LINK]
    }.flatten
    events = EventTable.find_many(event_ids)
    events_by_id = events.collect { |e| [e[EVENT_ID], e] }.to_h
    MultipleContractsAndEvents.new(
      contracts_and_events: contract_records.collect { |c|
        events = c[EVENTS_LINK].collect { |eid| events_by_id[eid] }
        ContractAndEvents.new(contract: c, events: events)
      }
    )
  end

end

# names = []
# month = Month.new(2022, 1)
# while month < Month.new(2023, 2)
#   puts("Processing #{month}")
#   contracts = MultipleContractsAndEvents.read_many(date_range: month)
#   month += 1
#   month_names = contracts.contracts_and_events.collect {|ce| ce.event_name}.sort
#   names += month_names
# end
#
# names.sort.uniq.each {|n| puts n}