require_relative 'authorise-sheets'

def get_sheets_service()
  service = Google::Apis::SheetsV4::SheetsService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize
  service
end
