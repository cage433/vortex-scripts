require_relative 'contracts'
require_relative 'event_table'
include ContractsColumns
include EventTableColumns

class ContractAndEvents
  attr_reader :contract, :events
  def initialize(contract:, events:)
    @contract = contract
    @events = events
  end

  def total_ba_tickets
    @events.collect{|e| e[BA_TICKETS] || 0}.sum
  end

  def total_b_tickets
    @events.collect{|e| e[B_TICKETS] || 0}.sum
  end

  def total_c_tickets
    @events.collect{|e| e[C_TICKETS] || 0}.sum
  end

  def total_d_tickets
    @events.collect{|e| e[D_TICKETS] || 0}.sum
  end

  def total_e_tickets
    @events.collect{|e| e[E_TICKETS] || 0}.sum
  end

  def total_promo_tickets
    @events.collect{|e| e[PROMO_TICKETS] || 0}.sum
  end

  def total_ticket_count
    total_ba_tickets + total_b_tickets + total_c_tickets + total_d_tickets + total_e_tickets + total_promo_tickets
  end

  def event_name
    @contract[EVENT_TITLE]
  end

  def standard_ticket_price
    @contract[STANDARD_TICKET_PRICE] || 0
  end

  def standard_ticket_value
    @events.collect{|e|
      e[STANDARD_TICKET_VALUE_HISTORIC] || (e.b_tickets_sold * standard_ticket_price)
    }.sum
  end

  def member_ticket_value
    @events.collect{|e| e.member_ticket_value(standard_ticket_price)}.sum
  end

  def student_ticket_value
    @events.collect{|e| e.student_ticket_value}.sum

  end
  def total_ticket_value
    standard_ticket_value + member_ticket_value + student_ticket_value
  end

end

class MultipleContractsAndEvents
  attr_reader :contracts_and_events
  def initialize(contracts_and_events:)
    @contracts_and_events = contracts_and_events
  end
  def total_ticket_count
    @contracts_and_events.collect { |ce| ce.total_ticket_count }.sum
  end

  def total_ticket_value
    @contracts_and_events.collect { |ce| ce.total_ticket_value }.sum
  end
  def self.read_many(date_range:)

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