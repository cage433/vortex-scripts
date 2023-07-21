# frozen_string_literal: true
require_relative '../env'
require_relative 'utils/tab_controller'
require_relative 'utils/workbook_controller'

class NominalLedgerController < TabController
  LEDGER_TAB_NAME = "Ledger"

  def initialize(wb_controller)
    super(wb_controller, LEDGER_TAB_NAME)
  end

  def read_invoices_from_sheet()
    range = sheet_range(
      top_left: SheetCell.from_row_and_col(0, 0),
      num_rows: nil,
      num_cols: 10,
    )
    get_spreadsheet_values(range)[1..]
  end
end

controller = WorkbookController.new(NOMINAL_LEDGER_SPREADSHEET_ID)
nlc = NominalLedgerController.new(controller)
invoices = nlc.read_invoices_from_sheet()
invoices.each do |invoice|
  puts invoice.join(", ")
end
