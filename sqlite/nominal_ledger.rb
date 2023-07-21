require 'sqlite3'
require_relative '../ledger/ledger'
require_relative '../env'
require 'parallel'
require_relative '../kashflow/api'

module ActivityReportColumns
  TABLE = "ActivityReport"
  INVOICE_DATE = "InvoiceDate"
  PAID_DATE = "PaidDate"
  REFERENCE = "Reference"
  PARTY = "Name"
  MONEY_IN = "MoneyIn"
  MONEY_OUT = "MoneyOut"
  VAT_IN = "VATIn"
  VAT_OUT = "VATOut"
  NOTE = "Note"
  TYPE = "Type"
end

# noinspection RubyDefParenthesesInspection
class ActivityReportTable

  include ActivityReportColumns

  def initialize(path)
    @path = path
  end

  def create_db(force = FALSE)
    if force
      File.delete(@path) if File.exist?(@path)
    end
    db = SQLite3::Database.open @path
    stmt = db.prepare(
      "CREATE TABLE IF NOT EXISTS
          #{TABLE} (
            #{INVOICE_DATE} TEXT,
            #{PAID_DATE} TEXT,
            #{REFERENCE} TEXT,
            #{NAME} TEXT,
            #{MONEY_IN} NUM,
            #{MONEY_OUT} NUM,
            #{VAT_IN} NUM,
            #{VAT_OUT} NUM,
            #{NOTE} TEXT,
            #{TYPE} TEXT,
          )
      ")
    stmt.execute
    stmt.close

  end

  def items()
    begin
      db = SQLite3::Database.open @path
      db.results_as_hash = true
      query_stmt = db.prepare("SELECT * FROM #{TABLE}")
      result = query_stmt.execute
      items = result.collect { |row|
        LedgerItem.new(
          code: row[CODE],
          type: row[TYPE],
          date: Date.parse(row[DATE]),
          reference: row[REFERENCE] || "",
          narrative: row[NARRATIVE] || "",
          debit: row[NET_DEBIT].to_f,
          credit: row[NET_CREDIT].to_f
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

  def self.num_debits()
    db = SQLite3::Database.open 'ledger.db'
    db.get_first_value("SELECT COUNT(*) FROM #{TABLE} WHERE #{NET_DEBIT} > 0")
  end

  def self.write(new_items)
    begin
      db = SQLite3::Database.open 'ledger.db'
      stmt = db.prepare("INSERT INTO #{TABLE} (#{CODE}, #{TYPE}, #{DATE}, #{REFERENCE}, #{NARRATIVE}, #{NET_DEBIT}, #{NET_CREDIT}) VALUES (?, ?, ?, ?, ?, ?, ?)")
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

num_debits = NominalLedgerTable.num_debits()
puts "Have ledger, num_debits = #{num_debits}"

receipts = read_kashflow_receipts(start_page = 1, end_page = 1)
puts "Have receipts, size = #{receipts.length}"
# ledger2 = Ledger.read_from_csv(File.join(Dir.home, 'Downloads', 'NominalLedgerReport.csv'))
# puts "Have ledger, size = #{ledger1.length}"
# new_items1 = ledger2 - ledger1
# new_items2 = ledger1 - ledger2
# puts "New items1: #{new_items1.length}"
# puts "New items2: #{new_items2.length}"
