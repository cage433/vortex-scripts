require 'airrecord'
require 'date'
require_relative 'event_table'
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
      table: self,
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
  FULLY_IMPROVISED = "Fully Improvised"
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

module ContractTableColumns
  EVENT_TITLE = "Event title"
  PERFORMANCE_DATE = "Performance date"
  VS_FEE = "VS fee?"
  PERCENTAGE_SPLIT_TO_ARTIST = "Percentage split to Artist"
  FLAT_FEE_TO_ARTIST = "Flat Fee to Artist"
end

class ContractTable < Airrecord::Table
  include ContractTableColumns
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = "Contracts"

  def self.fee_details_for_date(date)
    recs = select_with_date_filter(
      table: ContractTable,
      fields: [EVENT_TITLE, VS_FEE, PERCENTAGE_SPLIT_TO_ARTIST, FLAT_FEE_TO_ARTIST],
      date_field: PERFORMANCE_DATE,
      first_date: date, 
      last_date: date
    )

    if recs.size != 1
      FeeDetails.error_details("Expected a single contract, got #{recs.size} for date #{date}")
    else
      rec = recs[0]
      percentage_split = rec[PERCENTAGE_SPLIT_TO_ARTIST].to_f
      flat_fee = rec[FLAT_FEE_TO_ARTIST].to_f
      vs_fee = (rec[VS_FEE] || false)
      FeeDetails.new(flat_fee: flat_fee, percentage_split: percentage_split, vs_fee: vs_fee, error_text: nil)
    end
  end
end
