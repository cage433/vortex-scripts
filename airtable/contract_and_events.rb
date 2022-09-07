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

  def contract_hire_fee
    @contract.hire_fee
  end

  def total_event_hire_fee
    @events.collect{|e| e.total_hire_fee}.sum

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

  def cash_ticket_value
    @events.collect{|e| e.cash_ticket_value}.sum
  end

  def total_ticket_value
    standard_ticket_value + member_ticket_value + student_ticket_value + cash_ticket_value
  end

  def zettle_reading
    @events.collect{|e| e.zettle_reading}.sum
  end


  def bar_takings
    # Note the incorrect subtraction of student_ticket_value - for now mirroring the daily takings data spreadsheet
    zettle_reading - cash_ticket_value - student_ticket_value - member_ticket_value
  end

  def live_payable
    if @contract.is_vs_fee?
      max(@contract.flat_fee_to_artist, @contract.percentage_split_to_artist * total_ticket_value)
    else
      @contract.flat_fee_to_artist + @contract.percentage_split_to_artist * total_ticket_value
    end
  end

  def prs_fee
    if @contract.is_prs_payable?
      if @contract.is_streaming?
        Contracts::STREAMING_PRS_FEE
      else
        total_ticket_value * Contracts::PRS_RATE
      end
    else
      0
    end
  end

  def hire_fee
    @contract.hire_fee + @events.collect{|e| e.total_hire_fee}.sum
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

  def total_ticket_value
    @contracts_and_events.collect { |ce| ce.total_ticket_value }.sum
  end

  def total_student_ticket_value
    @contracts_and_events.collect { |ce| ce.student_ticket_value }.sum
  end

  def total_standard_ticket_value
    @contracts_and_events.collect { |ce| ce.standard_ticket_value }.sum
  end

  def total_member_ticket_value
    @contracts_and_events.collect { |ce| ce.member_ticket_value }.sum
  end

  def total_bar_takings_ex_vat
    @contracts_and_events.collect { |ce| ce.bar_takings }.sum / VAT_RATE
  end

  def total_prs_fee_ex_vat
    @contracts_and_events.collect { |ce| ce.prs_fee }.sum / VAT_RATE
  end

  def total_hire_fee
    @contracts_and_events.collect { |ce| ce.hire_fee }.sum
  end

  def total_zettle_reading
    @contracts_and_events.collect { |ce| ce.zettle_reading }.sum
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
