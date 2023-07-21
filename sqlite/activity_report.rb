require 'sqlite3'
require 'parallel'
require 'set'
require_relative '../ledger/ledger'
require_relative '../env'
require_relative '../kashflow/api'
require_relative '../kashflow/invoice'

module ActivityReportColumns
  TABLE = "ActivityReport"
  INVOICE_DATE = "InvoiceDate"
  PAID_DATE = "PaidDate"
  REFERENCE = "Reference"
  PARTY = "Party"
  NET = "Net"
  VAT = "VAT"
  TYPE = "Type"
  NOTE = "Note"
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
    stmt = db.prepare(%{CREATE TABLE IF NOT EXISTS #{TABLE} ( #{INVOICE_DATE} TEXT, #{PAID_DATE} TEXT, #{REFERENCE} TEXT, #{PARTY} TEXT, #{NET} NUM, #{VAT} NUM, #{NOTE} TEXT, #{TYPE} TEXT ) })
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
        issue_date = Date.parse(row[INVOICE_DATE])
        paid_date = if row[PAID_DATE].nil? || row[PAID_DATE].empty?
                      nil
                    else
                      Date.parse(row[PAID_DATE])
                    end
        Invoice.new(
          issue_date: issue_date,
          paid_date: paid_date,
          reference: row[REFERENCE],
          party: row[PARTY],
          net: row[NET],
          vat: row[VAT],
          note: row[NOTE],
          type: row[TYPE],
        )
      }
      query_stmt.close
      items
    ensure
      db.close if db
    end
  end

  def write(new_items)
    begin
      db = SQLite3::Database.open @path
      stmt = db.prepare(
        "INSERT INTO #{TABLE}
        (#{INVOICE_DATE}, #{PAID_DATE}, #{REFERENCE}, #{PARTY}, #{NET}, #{VAT}, #{NOTE}, #{TYPE})
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
      )
      new_items.each { |item|
        if item.paid_date.nil?
          paid_date = nil
        else
          paid_date = item.paid_date.to_s
        end
        puts "Inserting #{item}"
        stmt.execute item.issue_date.to_s, paid_date, item.reference, item.party, item.net, item.vat, item.note, item.type
      }
      stmt.close
    rescue SQLite3::Exception => e
      puts "Exception occurred"
    ensure
      db.close if db
    end
  end

end

invoices = Invoices.from_kashflow_activity_csv()
puts "Have invoices, size = #{invoices.length}"
table = ActivityReportTable.new(ACTIVITY_REPORT_DB_PATH)
# table.create_db
# table.write(invoices)
db_invoices = table.items()

puts "Have db invoices, size = #{db_invoices.length}"
for invoice in db_invoices
  if !invoices.include?(invoice)
    puts invoice
  end
end


