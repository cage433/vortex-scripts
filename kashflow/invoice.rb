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
      puts(downloads)
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
      File.readlines(file_path).each do |line|
        terms = line.split(',').collect do |term|
          term.gsub('"', '').strip
        end
        begin
          invoices.add(Invoice.from_kashflow_activity_csv_terms(terms))
        rescue => _
          LOG.warn("Ignoring line #{terms}")
        end
      end
      invoices
    end
  end
end

class Invoice
  attr_reader :issue_date, :paid_date, :reference, :ex_ref, :party, :money, :vat, :type

  def initialize(issue_date, paid_date, reference, ex_ref, party, money, vat, type)
    @issue_date = issue_date
    @paid_date = paid_date
    @reference = reference
    @ex_ref = ex_ref
    @party = party
    @money = money
    @vat = vat
    @type = type
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
    Invoice.new(issue_date, paid_date, reference, ex_ref, party, money, vat, type)
  end
end

invoices = Invoices.from_kashflow_activity_csv()
puts(invoices.size)
