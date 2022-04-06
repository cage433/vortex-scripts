require_relative '../airtable/contracts'
include ContractsColumns
contracts_by_event_date = Contracts._select(
  fields:[CODE, PERFORMANCE_DATE], first_date:Date.new(2010, 1, 1),last_date: Date.new(2030, 1, 1)
)
foo = Contracts.all(
  # fields:[CODE, PERFORMANCE_DATE],
  view:"Gigs to report"
)
foo.each {|rec|
  puts rec[CODE]

}
# contracts_by_event_date.each do |rec|
#   # puts "#{rec[CODE]}, #{rec[PERFORMANCE_DATE]}, #{rec[PERFORMANCE_DATE].class}"
#   foo = Date.parse(rec[PERFORMANCE_DATE])
#   if foo.class != Date
#     puts(foo.class)
#   end
# end
