require_relative '../controller/nm_controller'

def airtable_spike()
  perf_data = NMForm_SessionData.new(
    mugs: NumberSoldAndValue.new(number: 1, value: 8),
    t_shirts: NumberSoldAndValue.new(number: 10, value: 123),
    masks: NumberSoldAndValue.new(number: 2, value: 3.5),
    bags: NumberSoldAndValue.new(number: 4, value: 400),
    zettle_z_reading: 123.5,
    cash_z_reading: 121,
    notes: "blah blah blah\nfoo bar",
    fee_to_pay: 100,
    fully_improvised: true,
    prs_to_pay: 200,
  )

  ticket_sales = [1, 2].collect { |i| 
    NMFormTicketSales.new(
      gig: "Gig #{i}",
      online: NumberSoldAndValue.new(number: i * i, value: 8 + i),
      walk_ins: NumberSoldAndValue.new(number: 3 * i, value: 80 - i),
      guests_and_cheap: NumberSoldAndValue.new(number: 10 * i, value: 18 * i),
    )
  }

  expenses_data = [["Beer", 10.0], ["Gin", 111.0]].collect do |note, amt|
    NMForm_ExpensesData.new(
      note: note,
      amount: amt
    )
  end
  event_date =  DateTime.new(2021, 12, 22)
  form_data = NMForm_Data.new(
      date: event_date,
      session_data: perf_data,
      ticket_sales: ticket_sales,
      expenses_data: expenses_data
  )
  NMFormController.write_nm_form_data(
    form_data: form_data
  )

  form_data2 = NMFormController.read_nm_form_data(date: event_date)
    
end

def sync_sheets_for_date(date, force=false)
  wb_controller = WorkbookController.new(NIGHT_MANAGER_SPREADSHEET_ID)
  titles = EventTable.event_titles_for_date(date)
  sheet_data = NMFormController.read_nm_form_data(date: date)
  puts("titles = #{titles}")
  puts("Sheet data")
  puts(sheet_data.class)
  puts("returning")
  return 0
  
  tab_name = TabController.tab_name_for_date(date)
  build_required = force
  if !wb_controller.has_tab_with_name?(tab_name)
    wb_controller.add_tab(tab_name)
    build_required = true
  end
  tab_controller = NightManagerTabController.new(date, wb_controller)
  if build_required 
    tab_controller.build_sheet()
  end
  airtable_data = NMFormController.read_nm_form_data(date: date)
  if ! airtable_data.nil?
    tab_controller.set_nm_form_data(form_data: airtable_data)
  end
  form_data_again = tab_controller.read_nm_form_data()
end
sync_sheets_for_date(Date.new(2022, 3, 5), force=true)
