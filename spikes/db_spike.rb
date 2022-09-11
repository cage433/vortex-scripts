require 'sqlite3'

begin
  db = SQLite3::Database.open 'test.db'
  db.execute "CREATE TABLE IF NOT EXISTS nominal_ledger(
    code INT, type TEXT, date TEXT, reference TEXT, narrative TEXT, debit NUM, credit NUM
  )"
ensure
  db.close if db
end
