# frozen_string_literal: true

require 'csv'
require 'date'
require 'time'
require_relative '../date_range/date_range'
require_relative '../utils/utils'

prs_csv_path = "/Users/alex/vortex/PRS-2018-19.csv"
tidy_prs_csv_path = "/Users/alex/vortex/PRS-2018-19_tidy.csv"
mvt_csv_path = "/Users/alex/vortex/MVT Payments 2018-22.csv"

class MVTItem
  attr_reader :month, :receipts, :royalty_due

  def initialize(month, receipts, royalty_due)
    @month = month
    @receipts = receipts
    @royalty_due = royalty_due
  end

end

class MVTItems
  attr_reader :items

  def initialize(items)
    @items = items
  end

  def size
    @items.size
  end

  def total_received
    @items.collect {|item| item.receipts}.sum
  end
  def total_royalties
    @items.collect {|item| item.royalty_due}.sum
  end
  def self.amount_from_text(text)
    if text.nil? || text.strip == ""
      0.0
    else
      text=text.sub("£", "")
      text.to_f
    end
  end

  def self.from_csv(csv_path)
    items = []
    CSV.foreach(csv_path, headers: true) do |row|
      if row[0].nil? || row[0].strip == "" || row[0].strip == "Month"
        next
      end
      date = Date.parse(row[0])
      month = Month.containing(date)
      receipts = MVTItems.amount_from_text(row[1])
      royalty = MVTItems.amount_from_text(row[2])
      items.push(MVTItem.new(month, receipts, royalty))
    end
    MVTItems.new(items)
  end

  def item_for_month(month)
    @items.find {|item| item.month == month}
  end

  def limit_to(first_month: nil, last_month: nil)

    items = @items
    if first_month
      items = items.select {|item| item.month >= first_month}
    end
    if last_month
      items = items.select {|item| item.month <= last_month}
    end
    MVTItems.new(items)
  end
end

class PRSItem
  attr_reader :date, :title, :receipts, :current, :improvised

  def initialize(date, title, receipts, current, improvised)
    @date = date
    @title = title
    @receipts = receipts
    @current = current
    @improvised = improvised
  end

  def to_s
    [date, title, receipts, current, improvised].join(", ")
  end

  def self.extract_title(text)
    title = text.split("\n")[0].strip
    title = title.match(/(Name of Event: )?(.*)/)[2]
    title = title.match(/([A-Za-z -]*).*/)[1]
    title = title.strip
    if title[-1] == "-"
      title = title[0..-2]
    end
    title.gsub(",", ";")
  end

  def self.from_csv_row(row)
    text = row[2]
    maybe_date = Date.parse(row[0])
    if maybe_date > Date.new(2018, 8, 1)
      date = maybe_date
      format = /Box office receipts:\s*([0-9.]+).*/
      receipts = text.match(format)[1].to_f
    else
      format = /-\s*(\d{1,2}\/\d{1,2}\/\d{4})\.?\s*Box office receipts:\s*([0-9.]+).*/
      match_data = text.match(format)
      raise "Mismatch ...#{text}" unless match_data.captures.size == 2
      date = Date.parse(match_data[1])
      receipts = match_data[2].to_f
    end
    title = PRSItem.extract_title(text)
    current = row[3].to_f
    improvised = row[4].downcase == "true"
    new(date, title, receipts, current, improvised)
  end
end

class PRSItems
  attr_reader :items

  def initialize(items)
    @items = items
  end

  def size
    @items.size
  end

  #noinspection RubyNilAnalysis
  def self.from_csv(csv_path)
    csv = CSV.read(csv_path)
    items = csv[1..].collect { |row| PRSItem.from_csv_row(row) }
    new(items)
  end

  def for_month(month)
    PRSItems.new(
      @items.select { |item| Month.containing(item.date) == month }
    )
  end

  def total_receipts
    @items
      .collect {|item| item.receipts}
      .sum
  end

  def total_royalties
    @items
      .collect {|item| item.current}
      .sum
  end

  def sans_improvised
    PRSItems.new(
      @items.select {|item| !item.improvised}
    )
  end

  def total_royalties_sans_minimum
    @items
      .collect {|item|
        if item.date <= Date.new(2018, 6, 11)
          rate = 0.03
        else
          rate = 0.04
        end
        item.receipts * rate
      }
      .sum
  end

  def duplicated_gigs
    PRSItems.new(
      @items.group_by {|item| item.date}.select {|_, items| items.size > 1}.values.flatten().sort_by { |item| item.date }
    )
  end
end

prs_items = PRSItems.from_csv(prs_csv_path)
mvt_items = MVTItems.from_csv(mvt_csv_path)
m = Month.new(2018, 3)
data = []
while m <= Month.new(2019, 12)
  prs_for_month = prs_items.for_month(m)
  total_receipts = prs_for_month.total_receipts
  mvt_for_month = mvt_items.item_for_month(m)
  prs_royalties = prs_for_month.total_royalties
  mvt_royalties = mvt_for_month.royalty_due
  sans_min = prs_for_month.sans_improvised.total_royalties_sans_minimum
  data += [[m, total_receipts, prs_royalties, mvt_royalties, sans_min, prs_royalties - sans_min]]
  # puts("#{m} PRS: #{prs_royalties} MVT: #{mvt_royalties} PRS (sans improvised): #{prs_royalties_sans_improvised}")
  m += 1
end
puts(tabulated(data, ["Month", "Receipts", "PRS Royalties", "MVT Royalties", "PRS Royalties (SM)", "Discrepancy"]))

# prs_items.duplicated_gigs.items.each {|item| puts(item)}

puts("Sans improvised or minimum")
puts(prs_items.sans_improvised.total_royalties_sans_minimum)
puts("Sans minimum")
puts(prs_items.total_royalties_sans_minimum)
puts("Sans improvised")
puts(prs_items.sans_improvised.total_royalties)
puts("PRS total")
puts(prs_items.total_royalties)
mvt_to_2019 = mvt_items
                .limit_to(first_month: Month.new(2018, 3), last_month: Month.new(2019, 12))
puts("MVT total")
puts(mvt_to_2019.total_royalties)
# prs_items.items.each {|item| puts(item)}
File.open(tidy_prs_csv_path, "w") do |f|
  f.puts "Date,Title,Receipts,PRS,Improvised"
  prs_items.items.sort_by{|item| item.date}.each do |item|
    f.puts "#{item.date},#{item.title.gsub(",", ";")},#{item.receipts},#{item.current},#{item.improvised}"
  end
end

