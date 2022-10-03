require 'csv'

FS = 28.chr

module LedgerCodes
  SOUND_ENGINEERING = 8871
end

class LedgerItem
  attr_reader :code, :type, :date, :reference, :narrative, :debit, :credit
  include LedgerCodes

  def initialize(code:, type:, date:, reference:, narrative:, debit:, credit:)
    @code = code
    @type = type
    @date = date
    @reference = reference
    @narrative = narrative.gsub('\n', "\n").gsub(/\n+/, "\n")  # Differences between airtable and CSV newline representation
    @debit = debit
    @credit = credit
  end

  def ==(other)
    @code == other.code &&
      @type == other.type &&
      @date == other.date &&
      @reference == other.reference &&
      @narrative == other.narrative &&
      @debit == other.debit &&
      @credit == other.credit
  end
  alias_method :eql?, :==

  def hash
    [@code, @type, @date, @reference, @narrative, @debit, @credit].hash
  end

  def self.from_line(line)
    terms = line.split(',').collect { |t| t.gsub('"', "") }

    code = terms[0].to_i
    type = terms[1]

    date = Date.parse(terms[2])
    raise "Invalid date #{date}" if date.year < 2000 || date.year > 2030

    reference = terms[3].gsub(FS, "")
    narrative = terms[4].gsub(FS, "\n")

    debit = terms[5].to_f
    credit = terms[6].to_f
    LedgerItem.new(
      code: code,
      type: type,
      date: date,
      reference: reference,
      narrative: narrative,
      debit: debit,
      credit: credit
    )
  end

  def <=> (other)
    [@code, @type, @date, @reference, @narrative, @debit, @credit] <=> [other.code, other.type, other.date, other.reference, other.narrative, other.debit, other.credit]
  end

  def to_s
    "#{@code}:#{type} - #{date}, #{@reference}, #{@debit} - #{@credit}"
  end

end

class Ledger
  include Enumerable
  attr_reader :ledger_items

  include LedgerCodes
  def initialize(ledger_items)
    @ledger_items = ledger_items
  end

  def sound_engineering_payments(period)
    filtered_items = @ledger_items.select { |li| li.code == SOUND_ENGINEERING && period.contains?(li.date) }
    filtered_items.collect { |li| li.debit - li.credit }.reduce(0, :+)
  end

  def length
    @ledger_items.length
  end

  def -(other)
    Ledger.new(@ledger_items - other.ledger_items)
  end

  def each
    @ledger_items.map{|item| yield item}
  end

  def self.read_from_csv(csv_file)
    lines = File.readlines(csv_file)
    raise "Malformed file" unless lines[4][1..4] == "CODE"
    lines = lines.drop(5)
    last_line = ""
    repaired_lines = []
    lines.each do |line|
      maybe_ledger_type = line[1..4].to_i
      if maybe_ledger_type >= 1000 && line[0] == '"' && line.length > 20
        if last_line != ""
          repaired_lines << last_line.gsub("\r",FS).gsub("\n",FS)
        end
        last_line = line
      else
        last_line += line
      end
    end
    repaired_lines << last_line.gsub("\r", FS).gsub("\n", FS)
    ledger_items = repaired_lines.collect { |line|
      LedgerItem.from_line(line) }
    Ledger.new(ledger_items.sort_by { |item| item.date })
  end

  def write_csv_file(csv_file)
    File.open(csv_file, "w") do |f|
      f.puts "Code,Type,Date,Reference,Narrative,Debit,Credit"
      @ledger_items.each do |item|
        f.puts "#{item.code},#{item.type},#{item.date},#{item.reference},#{item.narrative.gsub(",", "").gsub("\n", "\\n")},#{item.debit},#{item.credit}"
      end
    end
  end

  def self.from_latest_dump
    dump_dir = File.absolute_path(File.join(File.dirname(__FILE__), "..", "data", "ledger-dumps"))
    dump_files = Dir.glob(File.join(dump_dir, "*.csv")).sort
    raise "No dump files found in #{dump_dir}" if dump_files.length == 0
    latest = dump_files.last
    ledger = self.read_from_csv(latest)
    fixed_ledger_path = File.join(dump_dir, "fixed", "#{File.basename(latest)}-fixed.csv")
    unless File.exists?(fixed_ledger_path)
      ledger.write_csv_file(fixed_ledger_path)
    end
    ledger
  end
end

ledger = Ledger.from_latest_dump
puts(ledger.length)
ledger.write_csv_file(File.join(Dir.home, 'Downloads', 'NominalLedgerReportFixed.csv'))
