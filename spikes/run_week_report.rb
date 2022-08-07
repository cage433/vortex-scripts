require_relative '../airtable/contracts'
require_relative '../airtable/event_table'
require_relative '../airtable/contract_and_events'
require_relative '../model/event_personnel'
require_relative '../date_range/date_range'
include ContractsColumns
include EventTableColumns





weeks = [VortexWeek::WEEK_40_JUN_22, VortexWeek::WEEK_41_JUN_22]
weeks.each do |w|
  mce = MultipleContractsAndEvents.read_many(date_range: w)
  puts
  puts("#{w} #{mce.total_ticket_count}, #{mce.total_ticket_value}")
  mce.contracts_and_events.each do |ce|
    puts("#{ce.event_name} #{ce.total_ticket_value}")
  end
end