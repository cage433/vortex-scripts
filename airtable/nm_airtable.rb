require 'airrecord'
require 'date'
require_relative 'contract_table'
require_relative '../env'
require_relative '../utils/utils'
require_relative '../model/nm_model'



######################
#     Airtable
#######################
Airrecord.api_key = AIRTABLE_API_KEY 

module NMForm_Columns
  ID = "Record ID"
  PERFORMANCE_DATE = "Performance Date"
end

class NMForm_Table < Airrecord::Table
  include NMForm_Columns
  def self.base_key 
    VORTEX_DATABASE_ID
  end
  
  def self.records_for_date(date)
    select_with_date_filter(
      fields: nil,
      table: table_name,
      date_field: PERFORMANCE_DATE,
      first_date: date,
      last_date: date
    )

  end

  def self.destroy_records_for_date(date)
    records_for_date(date).each do |rec|
      rec.destroy
    end
  end
end

module NMForm_SessionColumns 
  include NMForm_Columns

  MUGS_NUMBER = "Mugs Number"
  MUGS_VALUE = "Mugs Value"
  MASKS_NUMBER = "Masks Number"
  MASKS_VALUE = "Masks Value"
  T_SHIRTS_NUMBER = "T-shirts Number"
  T_SHIRTS_VALUE = "T-shirts Value"
  BAGS_NUMBER = "Bags Number"
  BAGS_VALUE = "Bags Value"
  ZETTLE_Z_READING = "Zettle Z Reading"
  CASH_Z_READING = "Cash Z Reading"
  NOTES = "Notes"
  BAND_FEE = "Band Fee"
  PRS_FEE = "PRS Fee"
end

class NMForm_SessionTable < NMForm_Table
  include NMForm_SessionColumns

  self.table_name = "NM Form (Session)"

  def self.has_record?(date)
    !id_for_date(date).nil?
  end

  def self.id_for_date(date)
    records = records_for_date(date)
    if records.empty?
      nil
    else
      records[0][ID]
    end
  end

end

module NMForm_GigColumns

  include NMForm_Columns
  GIG = "Gig"
  ONLINE_NUMBER = "Online Number"
  ONLINE_VALUE = "Online Value"
  WALK_IN_NUMBER = "Walk-in Number"
  WALK_IN_VALUE = "Walk-in Value"
  GUESTS_AND_CHEAP_NUMBER = "Guests/Cheap Number"
  GUESTS_AND_CHEAP_VALUE = "Guests/Cheap Value"

  GIG_1 = "Gig 1"
  GIG_2 = "Gig 2"
end

class NMForm_GigTable < NMForm_Table
  include NMForm_GigColumns

  self.table_name = "NM Form (Gig)"


end

module NMForm_ExpensesColumns
  include NMForm_Columns
  NOTE = "Note"
  AMOUNT = "Amount"
end

class NMForm_ExpensesTable < NMForm_Table
  include NMForm_ExpensesColumns

  self.table_name = "NM Form (Expenses)"

end

