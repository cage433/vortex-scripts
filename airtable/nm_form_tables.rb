require 'date'
require 'airrecord'
require_relative '../env'
Airrecord.api_key = AIRTABLE_API_KEY 

module NMForm_PerformanceMeta
  TABLE = "NM Form (Performance)"

  ID = "Record ID"
  PERFORMANCE_DATE = "Performance Date"
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
end

class NMForm_PerformanceTable < Airrecord::Table
  include NMForm_PerformanceMeta

  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  def self.has_record?(date)
    !id_for_date(date).nil?
  end

  def self.id_for_date(date)
    # Ugly-ass nonsense to handle timezone related issues messing up comparisons
    first_date_formatted = (date - 1).strftime("%Y-%m-%d")
    last_date_formatted = (date + 1).strftime("%Y-%m-%d")
    filter_text = "AND({#{PERFORMANCE_DATE}} > '#{first_date_formatted}',{#{PERFORMANCE_DATE}} < '#{last_date_formatted}')"
    records = all(filter: filter_text)
    if records.empty?
      nil
    else
      records[0][ID]
    end
  end

end

module NMForm_GigMeta
  TABLE = "NM Form (Gig)"

  ID = "Record ID"
  PERFORMANCE_DATE = "Performance Date"
  GIG = "Gig"
  ONLINE_NUMBER = "Online Number"
  ONLINE_VALUE = "Online Value"
  WALK_IN_NUMBER = "Walk-in Number"
  WALK_IN_VALUE = "Walk-in Value"
  GUESTS_AND_CHEAP_NUMBER = "Guests/Cheap Number"
  GUESTS_AND_CHEAP_VALUE = "Guests/Cheap Value"
end

class NMForm_GigTable < Airrecord::Table
  include NMForm_GigMeta

  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE


  def self.ids_for_date(date)
    # Ugly-ass nonsense to handle timezone related issues messing up comparisons
    first_date_formatted = (date - 1).strftime("%Y-%m-%d")
    last_date_formatted = (date + 1).strftime("%Y-%m-%d")
    filter_text = "AND({#{PERFORMANCE_DATE}} > '#{first_date_formatted}',{#{PERFORMANCE_DATE}} < '#{last_date_formatted}')"
    all(filter: filter_text).collect { |rec| rec[ID] }
  end

end

