# frozen_string_literal: true
require_relative '../google-sheets/utils/workbook_controller'
require_relative '../google-sheets/utils/sheet_range'
require_relative '../env.rb'
require 'rexml/document'


class Transaction
  attr_reader :id, :date, :name, :type, :amount, :category
  def initialize(id, date, name, type, amount, category)
    assert_type(date, Date)
    assert_type(id, Integer)
    assert_type(amount, Numeric)
    @id = id
    @date = date
    @type = type
    @name = name
    @amount = amount
    @category = category
  end
end

class BankAccount
  attr_reader :name, :bank_id, :acct_id, :transactions
  def initialize(name, acct_id, transactions)
    @name = name
    @acct_id = acct_id
    @transactions = transactions
  end
  def add_transaction(transaction)
    @transactions.push(transaction)
  end
  def new_transactions(transactions)
    transactions_by_id = @transactions.to_h {|t| [t.id, t]}
    transactions.reject { |t| transactions_by_id.has_key?(t.id) }
  end
end

class BankStatementController
  HEADERS = ["Transaction ID", "Date", "Payment Type", "Name", "Amount", "Category"]
  ACCOUNT_IDS_BY_TAB_NAMES = { "Current" => CURRENT_ACCOUNT_ID, "Savings" => SAVINGS_ACCOUNT_ID, "BBL" => BBL_ACCOUNT_ID, "Charity" => CHARITABLE_ACCOUNT_ID }

  def initialize
    # @tab_name = "Sheet1"
    @wb_controller = WorkbookController.new(BANK_STATEMENT_ID)
    # @sheet_id = @wb_controller.tab_ids_by_name()[@tab_name]
    @width = HEADERS.length
    # @sheet_range = SheetRange.new(
    #   SheetCell.from_coordinates("A1"),
    #   100,
    #   @width,
    #   @sheet_id, @tab_name
    # )
    header_range = SheetRange.new(
      SheetCell.from_coordinates("A1"),
      1,
      @width,
      @sheet_id, @tab_name
    )
    # header_range = @sheet_range.row(0)
    # @wb_controller.set_data(header_range, HEADERS)
  end

  def account(tab_name)
    sheet_range = SheetRange.new(
      SheetCell.from_coordinates("A1"),
      nil,
      @width,
      @sheet_id, tab_name
    )
    rows = @wb_controller.get_spreadsheet_values(sheet_range)
    acct_id = ACCOUNT_IDS_BY_TAB_NAMES[tab_name]
    acct = BankAccount.new(tab_name, acct_id, [])
    rows[1..].each do |row|
      row += [""] * (@width - row.length)
      id, date, name, type, amount, category = row
      transaction = Transaction.new(id.to_i, Date.parse(date), name, type, amount.to_f, category)
      acct.add_transaction(transaction)
    end
    acct
  end

  def self.transactions_from_file(file)
    doc = REXML::Document.new(file)
    elements = doc.elements.to_a("OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN")
    transactions = []
    elements.each do |e|
      date = Date.parse(e.text("DTPOSTED"))
      transaction = Transaction.new(
        e.text("FITID").to_i,
        date,
        (e.text("TRNTYPE") || "").strip,
        e.text("NAME"),
        e.text("TRNAMT").to_f,
        nil
      )
      transactions << transaction
    end
    transactions
  end

  def upload_file(acct_name, file)
    doc = REXML::Document.new(file)
    acct_details = doc.elements.to_a("OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS/BANKACCTFROM")
    acct_id = ACCOUNT_IDS_BY_TAB_NAMES[acct_name]
    if acct_details[0].text("ACCTID").to_i != acct_id
      raise "Account ID #{acct_id} does not match #{acct_details[0].text("ACCTID")}"
    end
    elements = doc.elements.to_a("OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN")
    rows = [HEADERS]
    elements.each do |e|
      date = Date.parse(e.text("DTPOSTED"))
      row = [e.text("FITID").strip, date, e.text("TRNTYPE"), e.text("NAME"), e.text("TRNAMT").to_f]
      rows << row
    end
    sheet_id = @wb_controller.tab_ids_by_name()[acct_name]
    sheet_range = SheetRange.new(
      SheetCell.from_coordinates("A1"),
      rows.length,
      @width,
      sheet_id, acct_name
    )
    @wb_controller.set_data(sheet_range, rows)

  end
end

bs = BankStatementController.new()
file = File.new(File.absolute_path(File.join("/Users", "alex", "vortex", "bank statements", "20230412_61414372.ofx")))
# bs.upload_file("Current", file)
file_transactions = BankStatementController.transactions_from_file(file)
existing_account = bs.account("Current")
new_transactions = file_transactions.reject{|t| existing_account.transactions.any?{|et| et.id == t.id}}

acct = bs.account("Current")
total_payments = acct.transactions.collect{|t| t.amount}.sum
puts "#{acct.acct_id}, #{total_payments}"