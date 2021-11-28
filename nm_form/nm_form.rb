require_relative '../airtable/nm_airtable'
require_relative '../google-sheets/nm_tab_controller'


class NMFormController

  def self.write_nm_performance_data(date, data)
    include NMForm_SessionColumns
    assert_type(data, NMForm_SessionData)
    NMForm_SessionTable.destroy_records_for_date(date)

    record = NMForm_SessionTable.new({})
    record[PERFORMANCE_DATE] = date
    record[MUGS_NUMBER] = data.mugs.number
    record[MUGS_VALUE] = data.mugs.value
    record[T_SHIRTS_NUMBER] = data.t_shirts.number
    record[T_SHIRTS_VALUE] = data.t_shirts.value
    record[MASKS_NUMBER] = data.masks.number
    record[MASKS_VALUE] = data.masks.value
    record[BAGS_NUMBER] = data.bags.number
    record[BAGS_VALUE] = data.bags.value
    record[ZETTLE_Z_READING] = data.zettle_z_reading
    record[CASH_Z_READING] = data.cash_z_reading
    record[NOTES] = data.notes
    record[BAND_FEE] = data.fee_to_pay
    record[PRS_FEE] = data.prs_to_pay

    record.save
  end


  def self.write_nm_gig_data(date, datas)
    include NMForm_GigColumns
    raise "Expected two data, got #{datas}" unless datas.size == 2
    assert_collection_type(datas, NMForm_GigData)

    raise "Expected gigs 1 & 2" unless Set[GIG_1, GIG_2] == datas.collect{ |d| d.gig}.to_set

    NMForm_GigTable.destroy_records_for_date(date)

    datas.each { |d|
      record = NMForm_GigTable.new(PERFORMANCE_DATE => date)
      record[GIG] = d.gig
      record[ONLINE_NUMBER] = d.online.number
      record[ONLINE_VALUE] = d.online.value
      record[WALK_IN_NUMBER] = d.walk_ins.number
      record[WALK_IN_VALUE] = d.walk_ins.value
      record[GUESTS_AND_CHEAP_NUMBER] = d.guests_and_cheap.number
      record[GUESTS_AND_CHEAP_VALUE] = d.guests_and_cheap.value

      record.save
    }

  end

  def self.write_nm_expenses_data(date, datas)
    include NMForm_ExpensesColumns
    assert_collection_type(datas, NMForm_ExpensesData)
    NMForm_ExpensesTable.destroy_records_for_date(date)

    datas.each { |d|
      record = NMForm_ExpensesTable.new(PERFORMANCE_DATE => date)
      record[NOTE] = d.note
      record[AMOUNT] = d.amount
      record.save
    }
  end

  def self.write_nm_form_data(form_data:)
    write_nm_performance_data(form_data.date, form_data.session_data)
    write_nm_gig_data(form_data.date, form_data.gigs_data)
    write_nm_expenses_data(form_data.date, form_data.expenses_data)
  end
end

def airtable_spike()
  perf_data = NMForm_SessionData.new(
    mugs: NumberSoldAndValue.new(number: 1, value: 8),
    t_shirts: NumberSoldAndValue.new(number: 10, value: 123),
    masks: NumberSoldAndValue.new(number: 2, value: 3.5),
    bags: NumberSoldAndValue.new(number: 4, value: 400),
    zettle_z_reading: 123.5,
    cash_z_reading: 121,
    notes: "blah blah blah"
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
  NMFormController.write_nm_form_data(
      date: DateTime.new(2021, 10, 3),
      performance_data: perf_data,
      gigs_data: gigs_data,
      expenses: expenses_data
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
  if build_required || true
    tab_controller.build_sheet()
  end
  #form_data = tab_controller.nm_form_data()
  #puts(form_data)
  #NMFormController.write_nm_form_data(form_data: form_data)
end

sheet_spike()
#airtable_spike()
