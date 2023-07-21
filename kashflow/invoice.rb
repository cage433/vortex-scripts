# frozen_string_literal: true
require_relative '../utils/utils'
require_relative '../logging'
require 'date'

class Invoices
  attr_reader :invoices

  def initialize(invoices)
    invoices.each do |invoice|
      assert_type(invoice, Invoice)
    end
    @invoices = invoices
  end

  def length
    @invoices.length
  end

  def add(invoice)
    assert_type(invoice, Invoice)
    @invoices << invoice
  end

  def each
    @invoices.each do |invoice|
      yield invoice
    end
  end

  def size
    @invoices.size
  end

  def self.from_kashflow_activity_csv(file_path = nil)
    if file_path.nil?
      # Use the most recent file in ~/Downloads
      downloads = File.expand_path('~/Downloads/')
      if Dir.exist?(downloads)
        files = Dir.glob(File.join(downloads, "activty*.csv")) # Note Kashflow's misspelling
        files = files.sort_by { |file| File.mtime(file) }.reverse
        if files.size > 0
          LOG.info("Reading #{files[0]}")
          from_kashflow_activity_csv(files[0])
        else
          raise("No activity files found")
        end
      end
    else
      invoices = Invoices.new([])
      File.readlines(file_path).each_with_index do |line, i|
        terms = line.split(',').collect do |term|
          term.gsub('"', '').strip
        end
        begin
          invoices.add(Invoice.from_kashflow_activity_csv_terms(terms))
        rescue => _
          LOG.warn("Ignoring line #{i}, #{terms}")
        end
      end
      invoices
    end
  end
end

class Invoice
  attr_reader :issue_date, :paid_date, :reference, :party, :net, :vat, :type, :note

  def initialize(
    issue_date:,
    paid_date:,
    reference:,
    party:,
    net:,
    vat:,
    type:,
    note:
  )

    @issue_date = assert_type(issue_date, Date)
    @paid_date = assert_type(paid_date, Date, allow_null: true)
    @reference = assert_type(reference, String)
    @party = assert_type(party, String)
    @net = assert_type(net, Numeric)
    @vat = assert_type(vat, Numeric)
    @type = assert_type(type, String)
    @note = assert_type(note, String)
  end

  def self.from_kashflow_activity_csv_terms(terms)
    terms = terms.collect { |term| term.strip.gsub('"', '') }
    issue_date = Date.parse(terms[0])
    if terms[1] == "0"
      paid_date = nil
    else
      paid_date = Date.parse(terms[1])
    end
    reference = terms[2]
    ex_ref = terms[3]
    party = terms[4]
    if terms[5] == ""
      money = terms[6].to_f
      vat = terms[8].to_f
    else
      money = -terms[5].to_f
      vat = -terms[7].to_f
    end
    type = terms[9]
    if terms.size > 10
      note = terms[10]
    else
      note = ""
    end
    Invoice.new(
      issue_date: issue_date,
      paid_date: paid_date,
      reference: reference,
      party: party,
      net: money,
      vat: vat,
      type: type,
      note: note
    )
  end
end

# invoices = Invoices.from_kashflow_activity_csv()
# puts(invoices.size)
