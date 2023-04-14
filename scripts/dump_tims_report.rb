require_relative '../airtable/contracts'
puts "hi"

include ContractsColumns
recs = Contracts.all(view: "Gigs to report", sort: {PERFORMANCE_DATE => "asc", CODE => "asc"})
puts(events)
