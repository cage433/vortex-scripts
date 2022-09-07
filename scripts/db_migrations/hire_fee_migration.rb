require_relative '../../airtable/contract_and_events'
require_relative '../../date_range/date_range'
require 'parallel'


c_and_e = Parallel.map(2013..2023) do |year|
  puts(year)
  MultipleContractsAndEvents.read_many(date_range: Year.new(year)).contracts_and_events
end.flatten.filter { |ce| ce.contract_hire_fee != 0 || ce.total_event_hire_fee != 0 }

def move_hire_fee_to_event(ce)
  contract_fee = ce.contract_hire_fee
  puts("Updating #{ce.event_name}")
  raise "expected at least one event" unless ce.events.length > 0
  first_event = ce.events[0]
  first_event["Hire fee 2"] = contract_fee + ce.total_event_hire_fee
  first_event.save()

end
c_and_e.each { |ce|  move_hire_fee_to_event(ce)}