require 'airrecord'
require_relative '../ledger/ledger'
require_relative '../env'
require 'parallel'

Airrecord.api_key = AIRTABLE_API_KEY

module NominalLedgerColumns
  TABLE = "Nominal Ledger"
  ID = "Record ID"
  CODE = "Code"
  TYPE = "Type"
  DATE = "Date"
  REFERENCE = "Reference"
  NARRATIVE = "Narrative"
  DEBIT = "Debit"
  CREDIT = "Credit"
  ROW = "Row"
end

#noinspection RubyDefParenthesesInspection
class NominalLedgerTable < Airrecord::Table

  include NominalLedgerColumns

  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE


  def self.full()
    Ledger.new(
      Parallel.map(0..20) do |page|
        filters =
          [
            "{#{ROW}} >= #{page * 1000}",
            "{#{ROW}} < #{(page + 1) * 1000}"
          ]
        filter_text = "And(" + filters.join(", ") + ")"
        all(
          filter: filter_text
        ).collect { |rec|
          LedgerItem.new(
            code: rec[CODE],
            type: rec[TYPE],
            date: Date.parse(rec[DATE]),
            reference: rec[REFERENCE] || "",
            narrative: rec[NARRATIVE] || "",
            debit: rec[DEBIT].to_f,
            credit: rec[CREDIT].to_f
          )
        }
      end.flatten
    )

  end

end

# ledger1 = NominalLedgerTable.full()
# ledger2 = Ledger.read_from_csv(File.join(Dir.home, 'Downloads', 'NominalLedgerReport.csv'))
# puts "Have ledger, size = #{ledger1.length}"
# new_items1 = ledger2 - ledger1
# new_items2 = ledger1 - ledger2
# puts "New items1: #{new_items1.length}"
# puts "New items2: #{new_items2.length}"
