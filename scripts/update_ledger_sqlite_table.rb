require 'date'
require_relative '../sqlite/nominal_ledger'
require_relative '../logging.rb'
require 'sqlite3'

include NominalLedgerColumns

def update_ledger_table(csv_file)
  creation_date = Date.parse(File.ctime(csv_file).to_s)
  if creation_date != Date.today
    raise "ERROR: CSV file #{csv_file} was created on #{creation_date} but today is #{Date.today}"
  end
  ledger_csv = Ledger.read_from_csv(csv_file)
  ledger_sqlite = NominalLedgerTable.full()
  sqlite_extra = ledger_sqlite - ledger_csv
  if sqlite_extra.length > 0
    raise "ERROR: SQLite has #{sqlite_extra.length} extra items"
  end

  csv_extra = ledger_csv - ledger_sqlite
  if csv_extra.length > 0
    latest_sqlite_date = ledger_sqlite.ledger_items.collect { |item| item.date }.max
    earliest_csv_date = csv_extra.ledger_items.collect { |item| item.date }.min
    if !latest_sqlite_date.nil? && latest_sqlite_date > earliest_csv_date
      raise "ERROR: Latest airtable date is #{latest_sqlite_date}, earliest CSV date is #{earliest_csv_date}"
    end
    NominalLedgerTable.write(csv_extra)
  else
    puts "No extra items in CSV"
  end
end
csv_file = File.join(Dir.home, 'Downloads', 'NominalLedgerReport.csv')
update_ledger_table(csv_file)
