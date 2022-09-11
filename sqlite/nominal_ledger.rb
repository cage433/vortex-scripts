require 'sqlite3'
require_relative '../ledger/ledger'
require_relative '../env'
require 'parallel'

module NominalLedgerColumns
  TABLE = "NominalLedger"
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
class NominalLedgerTable

  include NominalLedgerColumns

  def self.ledger_items()
    begin
      db = SQLite3::Database.open 'ledger.db'
      db.results_as_hash = true
      stmt = db.prepare("CREATE TABLE IF NOT EXISTS #{TABLE} ( #{CODE} INT, #{TYPE} TEXT, #{DATE} TEXT, #{REFERENCE} TEXT, #{NARRATIVE} TEXT, #{DEBIT} NUM, #{CREDIT} NUM )")
      stmt.execute #"CREATE TABLE IF NOT EXISTS #{TABLE} ( #{CODE} INT, #{TYPE} TEXT, #{DATE} TEXT, #{REFERENCE} TEXT, #{NARRATIVE} TEXT, #{DEBIT} NUM, #{CREDIT} NUM )"
      stmt.close

      query_stmt = db.prepare("SELECT * FROM #{TABLE}")
      result = query_stmt.execute
      items = result.collect { |row|
        LedgerItem.new(
          code: row[CODE],
          type: row[TYPE],
          date: Date.parse(row[DATE]),
          reference: row[REFERENCE] || "",
          narrative: row[NARRATIVE] || "",
          debit: row[DEBIT].to_f,
          credit: row[CREDIT].to_f
        )
      }
      query_stmt.close
      items
    ensure
      db.close if db
    end
  end

  def self.full()
    Ledger.new(ledger_items())
  end

  def self.write(new_items)
    begin
      db = SQLite3::Database.open 'ledger.db'
      stmt = db.prepare("INSERT INTO #{TABLE} (#{CODE}, #{TYPE}, #{DATE}, #{REFERENCE}, #{NARRATIVE}, #{DEBIT}, #{CREDIT}) VALUES (?, ?, ?, ?, ?, ?, ?)")
      new_items.each { |item|
        puts "Inserting #{item}"
        stmt.execute item.code, item.type, item.date.to_s, item.reference, item.narrative, item.debit, item.credit
      }
      stmt.close
    rescue SQLite3::Exception => e
      puts "Exception occurred"
    ensure
      db.close if db
    end
  end

end

# ledger1 = NominalLedgerTable.full()
# ledger2 = Ledger.read_from_csv(File.join(Dir.home, 'Downloads', 'NominalLedgerReport.csv'))
# puts "Have ledger, size = #{ledger1.length}"
# new_items1 = ledger2 - ledger1
# new_items2 = ledger1 - ledger2
# puts "New items1: #{new_items1.length}"
# puts "New items2: #{new_items2.length}"
