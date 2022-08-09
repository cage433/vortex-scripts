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
  puts(w)
  puts("Tickets:          #{mce.total_ticket_count}")
  puts("Value:            #{mce.total_ticket_value}")
  puts("Bar (ex VAT):     #{mce.total_bar_takings_ex_vat}")
  puts("Student value:    #{mce.total_student_ticket_value}")
  puts("Zettle:           #{mce.total_zettle_reading}")
  puts("Musician Fees:    #{mce.total_zettle_reading}")
  puts("PRS Fee:          #{mce.total_prs_fee_ex_vat}")


  # mce.contracts_and_events.each do |ce|
  #   puts("        #{ce.event_name}")
  #   puts("            Total Ticket Value #{ce.total_ticket_value}")
  #   puts("            Bar Takings        #{ce.bar_takings}")
  #   puts("            Zettle             #{ce.zettle_reading}")
  #   puts("            PRS                #{ce.prs_fee}")
  # end
end