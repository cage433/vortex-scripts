require 'csv'
require_relative '../airtable/contracts'

downloads_dir = "/Users/alex/Downloads"
id_re = /\((\d+)\)/
csv_paths = Dir.glob("#{downloads_dir}/Contracts*.csv").select { |path| path.include?("(") }

latest_id = nil
latest_path = nil
csv_paths.each do |path|
  name = path.split("/")[-1]
  id = id_re.match(name).captures[0].to_i
  if latest_id.nil? || latest_id < id
    latest_id = id
    latest_path = path
  end
end

puts "Checking #{latest_path}"
latest_csv = CSV.read(latest_path)
original_csv = CSV.read("#{downloads_dir}/Original-report.csv")
raise "Mismatch in file lengths, latest #{latest_csv.size} vs #{original_csv.size}" \
  unless latest_csv.size == original_csv.size
cols_to_ignore = [0]
latest_csv.zip(original_csv).each_with_index { |l_and_r, i|
  l, r = l_and_r
  raise "length mismatch for line #{i}, #{l.size} vs #{r.size}" unless l.size == r.size
  l.zip(r).each_with_index { |x_and_y, j|
    x, y = x_and_y
    next if cols_to_ignore.include?(j)
    raise "Call mismatch for row #{i}, Col #{j} = #{l[0]}, Latest [#{x}] vs Original [#{y}]" unless x == y

  }

}
