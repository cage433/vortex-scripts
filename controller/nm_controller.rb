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

  def self.read_nm_performance_data(date)
    include NMForm_SessionColumns
    records = NMForm_SessionTable.records_for_date(date)
    if records.empty?
      nil
    else
      raise "Expected a single record for date #{date}" unless records.size == 1
      record = records[0]
      NMForm_SessionData.new(
        mugs: NumberSoldAndValue.new(number: record[MUGS_NUMBER], value: record[MUGS_VALUE]),
        t_shirts: NumberSoldAndValue.new(number: record[T_SHIRTS_NUMBER], value: record[T_SHIRTS_VALUE]),
        masks: NumberSoldAndValue.new(number: record[MASKS_NUMBER], value: record[MASKS_VALUE]),
        bags: NumberSoldAndValue.new(number: record[BAGS_NUMBER], value: record[BAGS_VALUE]),
        zettle_z_reading: record[ZETTLE_Z_READING],
        cash_z_reading: record[CASH_Z_READING],
        notes: record[NOTES],
        fee_to_pay: record[BAND_FEE],
        prs_to_pay: record[PRS_FEE]
      )
    end
  end

  def self.write_nm_ticket_sales(date, datas)
    include NMForm_GigColumns
    raise "Expected two data, got #{datas}" unless datas.size == 2
    assert_collection_type(datas, NMFormTicketSales)

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

  def self.read_nm_ticket_sales(date)
    include NMForm_GigColumns
    records = NMForm_GigTable.records_for_date(date)
    records.collect do |record|
      NMFormTicketSales.new(
        gig: record[GIG],
        online: NumberSoldAndValue.new(number: record[ONLINE_NUMBER], value: record[ONLINE_VALUE]),
        walk_ins: NumberSoldAndValue.new(number: record[WALK_IN_NUMBER], value: record[WALK_IN_VALUE]),
        guests_and_cheap: NumberSoldAndValue.new(number: record[GUESTS_AND_CHEAP_NUMBER], value: record[GUESTS_AND_CHEAP_VALUE])
      )
    end 
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

  def self.read_nm_expenses_data(date)
    include NMForm_ExpensesColumns
    records = NMForm_ExpensesTable.records_for_date(date)
    records.collect do |record|
      NMForm_ExpensesData.new(
        note: record[NOTE],
        amount: record[AMOUNT]
      )
    end 
  end

  def self.write_nm_form_data(form_data:)
    write_nm_performance_data(form_data.date, form_data.session_data)
    write_nm_ticket_sales(form_data.date, form_data.ticket_sales)
    write_nm_expenses_data(form_data.date, form_data.expenses_data)
  end

  def self.read_nm_form_data(date:)
    performance_data = read_nm_performance_data(date)
    if performance_data.nil?
      nil
    else
      NMForm_Data.new(
        date: date,
        session_data: performance_data,
        ticket_sales: read_nm_ticket_sales(date),
        expenses_data: read_nm_expenses_data(date)
      )
    end
  end
end

