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
    terms = line.split('","').collect { |t| t.gsub('"', "") }

    code = terms[0].to_i
    type = terms[1]

    date = Date.parse(terms[2])
    raise "Invalid date #{date}" if date.year < 2000 || date.year > 2030

    reference = terms[3].gsub(FS, "")
    narrative = terms[4].gsub(FS, "\n")


    debit = (terms[5] || "").gsub(',', '').to_f
    credit = (terms[6] || "").gsub(',', '').to_f
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

  def +(other)
    Ledger.new(@ledger_items + other.ledger_items)
  end

  def sound_engineering_payments(period)
    filtered_items = @ledger_items.select { |li| li.code == SOUND_ENGINEERING && period.contains?(li.date) }
    filtered_items.collect { |li| li.debit - li.credit }.reduce(0, :+)
  end

  def net_debit
    @ledger_items.collect { |li| li.debit }.reduce(0, :+)
  end
  def net_credit
    @ledger_items.collect { |li| li.credit }.reduce(0, :+)
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

  def self.break_into_sections(lines)
    sections = []
    next_section_lines = []
    i_line = 0
    lines.each do |line|
      i_line += 1
      terms = line.split('","')
      if terms[4] == 'TOTALS'
        net_debit = terms[5].gsub('"', '').gsub(',', '').to_f
        net_credit = terms[6].gsub('"', '').gsub(',', '').to_f
        sections.push([next_section_lines, net_debit, net_credit])
        next_section_lines = []
        next
      end
      if terms[4] == 'BALANCE'
        next
      end
      if terms.all? { |t| t.gsub('"', '').gsub(',', '').strip == "" }
        next
      end
      next_section_lines << line
    end
    sections
  end

  def self.process_line(line)
    LedgerItem.from_line(line)


  end
  def self.process_section(section)
    lines, net_debit, net_credit = section
    first_terms = lines[0].split('","')
    next_complete_line = ""
    items = []
    lines.each do |line|
      terms = line.split('","')
      if terms[0] == first_terms[0] && terms[1] == first_terms[1]
        if next_complete_line != ""
          items << LedgerItem.from_line(next_complete_line)
        end
        next_complete_line = line.gsub("\r",FS).gsub("\n",FS)
      else
        next_complete_line << line.gsub("\r",FS).gsub("\n",FS)
      end
    end
    items << LedgerItem.from_line(next_complete_line)
    ledger = Ledger.new(items.sort_by { |item| item.date })
    if (ledger.net_debit - net_debit).abs > 0.01 || (ledger.net_credit - net_credit).abs > 0.01
      raise "Net debit/credit mismatch"
    end
    ledger
  end

  def self.read_from_csv(csv_file)
    lines = File.readlines(csv_file)
    raise "Malformed file" unless lines[4][1..4] == "CODE"
    lines = lines.drop(5)

    sections = self.break_into_sections(lines)
    ledgers = sections.collect { |section| self.process_section(section) }
    ledgers.reduce(Ledger.new([])) { |a, e| a + e }
  end

  def write_csv_file(csv_file)
    File.open(csv_file, "w") do |f|
      f.puts "Code,Type,Date,Reference,Narrative,Debit,Credit"
      @ledger_items.each do |item|
        f.puts "#{item.code},#{item.type},#{item.date},#{item.reference.gsub(",", "").gsub("\n", "\\n")},#{item.narrative.gsub(",", "").gsub("\n", "\\n")},#{item.debit},#{item.credit}"
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
    unless File.exist?(fixed_ledger_path)
      ledger.write_csv_file(fixed_ledger_path)
    end
    ledger
  end
end

# ledger = Ledger.from_latest_dump
