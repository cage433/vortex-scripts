require 'kashflow_api'
require_relative '../env'

KashflowApi.configure do |c|
  c.username = "vortex"
  c.password = KASHFLOW_PASSWORD
  c.loggers = false
end
xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
            <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
            <soap:Body>
<GetNominalCodes xmlns=\"KashFlow\">
<UserName>vortex</UserName>
            <Password>N1611GVJ</Password>
</GetNominalCodes>
</soap:Body>
            </soap:Envelope>
"
ledger_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
            <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
            <soap:Body>
<GetNominalLedger xmlns=\"KashFlow\">
<UserName>vortex</UserName>
            <Password>N1611GVJ</Password>
<StartDate>2021-07-01</StartDate>
<EndDate>2021-07-31</EndDate>
<NominalID>2200</NominalID>
</GetNominalLedger>
</soap:Body>
            </soap:Envelope>
"
# foo = KashflowApi.client
# result = KashflowApi::ApiCall.new(:get_nominal_codes, xml).call
# result = KashflowApi.client.client.call(:get_nominal_codes, xml: xml)
result = KashflowApi.client.client.call(:get_nominal_ledger, xml: ledger_xml)
results = []
foo = result.hash[:envelope][:body][:get_nominal_ledger_response][:get_nominal_ledger_result][:transaction_information]
puts(foo)
# result.hash[:envelope][:body][:get_nominal_ledger_response][:get_nominal_ledger_result][:nominal_ledger].each do |r|
#   results.push r
# end
# puts(results)
# result.hash[:envelope][:body][:get_nominal_codes_response][:get_nominal_codes_result][:nominal_code].each do |r|
#   results.push r
# end
# puts(results)
# puts(ledger.length)
# ledger.each do |item|
#   puts "#{item.code} #{item.name}"
# end
