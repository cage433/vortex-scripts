require_relative 'google-sheets/workbook_controller.rb'
require_relative 'google-sheets/volunteer_tab_controller.rb'
require_relative 'google-sheets/night_manager_tab_controller.rb'
require_relative 'env'
require_relative 'airtable/volunteer_controller'
require_relative 'airtable/night_manager_controller'

def oct_airtable_events()
  VolunteerAirtableController.read_events_personnel(2021, 10)
end

def oct_sheet_events()
  wb_controller = WorkbookController.new(VOL_ROTA_SPREADSHEET_ID)
  VolunteerMonthTabController.new(2021, 10, wb_controller).read_events_personnel()
end
