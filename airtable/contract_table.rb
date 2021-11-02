require_relative '../env'
require_relative 'original_contracts_table'
require_relative '../utils/utils'
require_relative 'vortex_table'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module EventTableColumns
  TABLE = "Events"

  ID = "Record ID"
  SHEETS_EVENT_TITLE = "SheetsEventTitle"
  EVENT_DATE = "Event Date"
  DOORS_TIME = "Doors Time"
  SOUND_ENGINEER = "Sound Engineer"
  NIGHT_MANAGER_NAME = "Night Manager Name"
  VOL_1 = "Vol 1 Name"
  VOL_2 = "Vol 2 Name"
  STATUS = "Status"
  #FEE_NOTES = "Fee Notes"
  #FLAT_FEE = "Flat Fee"
  #MIN_FEE = "Min Fee"
  #FEE_PERCENTAGE = "Fee %age"
end

class EventTable < Airrecord::Table

  include EventTableColumns
   
  self.base_key = VORTEX_DATABASE_ID
  self.table_name = TABLE

  def self._select(fields:, first_date:, last_date:)
    select_with_date_filter(
      table: EventTable,
      fields: fields,
      date_field: EVENT_DATE,
      first_date: first_date,
      last_date: last_date,
      extra_filters: ["{#{STATUS}} = 'Confirmed'"]
    )
  end

  def self.ids_for_month(year, month_no)
    _select(
      fields: [ID],
      first_date: Date.new(year, month_no, 1),
      last_date: Date.new(year, month_no, -1)
    )
  end


  def self.event_title_for_date(date)
    recs = _select(
      fields: [SHEETS_EVENT_TITLE],
      first_date: date,
      last_date: date
    )
    titles = recs.collect { |rec| rec[SHEETS_EVENT_TITLE] }.uniq

    if titles.size == 1
      titles[0]
    else
      raise "Expected a single title, got #{titles}"
    end
  end
  

end

class FeeDetails
  attr_reader :flat_fee, :percentage_split, :vs_fee, :error_text

  def initialize(flat_fee:, percentage_split:, vs_fee:, error_text:)
    assert_type(flat_fee, Numeric)
    assert_type(percentage_split, Numeric)
    @flat_fee = flat_fee
    @percentage_split = percentage_split
    @vs_fee = vs_fee
    @error_text = error_text
  end

  def self.error_details(error_text)
    FeeDetails.new(flat_fee: 0, percentage_split: 0, vs_fee: false, error_text: error_text)
  end

  def to_s
    "Fee(flat: #{@flat_fee}, %age: #{@percentage_split}, VS: #{@vs_fee}, error: #{@error_text || 'None'})"
  end
  def has_flat_fee?
    @flat_fee > 0
  end
  def has_percentage?
    @percentage_split > 0
  end
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

def spike()
  [11].each do |d|
    date = Date.new(2021, 11, d)
    fee_details = ContractTable.fee_details_for_date(date)
    puts()
    puts(fee_details)
  end
end


