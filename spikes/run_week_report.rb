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
  puts("#{w} #{mce.total_ticket_count}")
  mce.contracts_and_events.each do |ce|
    puts("#{ce.event_name} #{ce.total_ticket_count}")
  end
end
# contracts_and_events = ContractAndEvents.read_many(date_range: week)
#
# ids = Contracts.ids_for_date_range(date_range: week)
#
# records = Contracts.find_many(ids)
# puts(week.to_s)
# events_links = records.collect {|rec|
#   rec[EVENTS_LINK]
# }.flatten
# # events_links.each { |e| puts(e) }
# events = EventTable.find_many(events_links)
# events.each do |e|
#   puts("")
#   puts(e[SHEETS_EVENT_TITLE])
#   puts(e[EVENT_DATE])
#   # e.fields.each do |k,v|
#   #   puts("#{k}: #{v}")
#   # end
#   puts("BA #{e[BA_TICKETS]}")
#   puts("B #{e[B_TICKETS]}")
#   puts("C #{e[C_TICKETS]}")
#   puts("D #{e[D_TICKETS]}")
#   puts("E #{e[E_TICKETS]}")
#   # puts(e[BA_TICKETS])
#   # puts(e[B_TICKETS])
#   # puts(e[C_TICKETS])
#   # puts(e[D_TICKETS])
#   # puts(e[E_TICKETS])
# end
#

