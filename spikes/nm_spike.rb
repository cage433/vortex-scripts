require_relative '../controller/nm_controller'

def airtable_spike()
  perf_data = NMForm_SessionData.new(
    mugs: NumberSoldAndValue.new(number: 1, value: 8),
    t_shirts: NumberSoldAndValue.new(number: 10, value: 123),
    masks: NumberSoldAndValue.new(number: 2, value: 3.5),
    bags: NumberSoldAndValue.new(number: 4, value: 400),
    zettle_z_reading: 123.5,
    cash_z_reading: 121,
    notes: "blah blah blah",
    fee_to_pay: 100,
    prs_to_pay: 200,
  )

  gigs_data = [1, 2].collect { |i| 
    NMForm_GigData.new(
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
  form_data = NMForm_Data.new(
      date: DateTime.new(2021, 10, 23),
      session_data: perf_data,
      gigs_data: gigs_data,
      expenses_data: expenses_data
  )
  NMFormController.write_nm_form_data(
    form_data: form_data
  )
    
end

def sheet_spike()
  date = Date.new(2021, 10, 23)
  wb_controller = WorkbookController.new(NIGHT_MANAGER_SPREADSHEET_ID)
  tab_name = TabController.tab_name_for_date(date)
  build_required = false
  if !wb_controller.has_tab_with_name?(tab_name)
    wb_controller.add_tab(tab_name)
    build_required = true
  end
  tab_controller = NightManagerTabController.new(date, wb_controller)
  if build_required 
    tab_controller.build_sheet()
  end
  form_data = tab_controller.nm_form_data()
  #puts(form_data)
  #NMFormController.write_nm_form_data(form_data: form_data)
end

#airtable_spike()
sheet_spike()