require 'rexml/document'

def foo
  path = File.absolute_path(File.join("/Users", "alex", "vortex", "bank statements", "20230412_61414372.ofx"))
  file = File.new(path)
  puts(File.exist?(path))
  doc = REXML::Document.new(file)
  elements = doc.elements.to_a("OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN")
  puts("Num elements #{elements.size}")
  elements.each do |e|
    puts("#{e.text("TRNTYPE")}, #{e.text("DTPOSTED")}, #{e.text("NAME")}, #{e.text("TRNAMT")} ")
  end
  # doc.elements.each("OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN") do |e|
  #   puts e.text("TRNTYPE")
  #   puts e.text("TRNAMT")
  # end
end


foo

