require 'date'
require_relative '../airtable/nominal_ledger'
require_relative '../logging.rb'

include NominalLedgerColumns

def update_ledger_table(csv_file)
  creation_date = Date.parse(File.ctime(csv_file).to_s)
  if creation_date != Date.today
    raise "ERROR: CSV file #{csv_file} was created on #{creation_date} but today is #{Date.today}"
  end
  ledger_csv = Ledger.read_from_csv(csv_file)
  ledger_airtable = NominalLedgerTable.full()
  airtable_extra = ledger_airtable - ledger_csv
  if airtable_extra.length > 0
    raise "ERROR: Airtable has #{airtable_extra.length} extra items"
  end

  csv_extra = ledger_csv - ledger_airtable
  if csv_extra.length > 0
    latest_airtable_date = ledger_airtable.ledger_items.collect { |item| item.date }.max
    earliest_csv_date = csv_extra.ledger_items.collect { |item| item.date }.min
    if latest_airtable_date > earliest_csv_date
      raise "ERROR: Latest airtable date is #{latest_airtable_date}, earliest CSV date is #{earliest_csv_date}"
    end
    csv_extra.each do |item|
      VOL_ROTA_LOGGER.info("Adding #{item}")
      NominalLedgerTable.create(
        CODE => item.code,
        TYPE => item.type,
        DATE => item.date,
        REFERENCE => item.reference,
        NARRATIVE => item.narrative,
        DEBIT => item.debit,
        CREDIT => item.credit
      )
    end
  else
    puts "No extra items in CSV"
  end
end
csv_file = File.join(Dir.home, 'Downloads', 'NominalLedgerReport.csv')
# update_ledger_table(csv_file)
