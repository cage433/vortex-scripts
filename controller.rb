require_relative 'google-sheets/workbook_controller.rb'
require_relative 'google-sheets/volunteer-sheet/controller.rb'
require_relative 'google-sheets/night-manager/controller.rb'
require_relative 'env'
require_relative 'airtable/event_table'
require_relative 'airtable/volunteer_controller'
require_relative 'airtable/night_manager_controller'
require 'date'

class Controller

  def initialize()
    @vol_rota_controller = WorkbookController.new(VOL_ROTA_SPREADSHEET_ID)
    @night_manager_controller = WorkbookController.new(NIGHT_MANAGER_SPREADSHEET_ID)
  end

  def vol_tab_controller(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    @vol_rota_controller.add_tab(tab_name) if !@vol_rota_controller.has_tab_with_name?(tab_name)
    VolunteerMonthTabController.new(year, month, @vol_rota_controller)
  end

  def night_manager_tab_controller(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    @night_manager_controller.add_tab(tab_name) if !@night_manager_controller.has_tab_with_name?(tab_name)
    NightManagerMonthTabController.new(year, month, @night_manager_controller)
  end

  def populate_vol_sheet(year, month)
    tab_controller = vol_tab_controller(year, month)
    sheet_events = tab_controller.read_events()
    airtable_events = VolunteerAirtableController.read_events_for_month(year, month)
    merged_events = sheet_events.merge(airtable_events)
    if merged_events.num_events > sheet_events.num_events
      puts("Adding missing events")
      tab_controller.replace_events(merged_events)
    end
  end

  def update_airtable_personnel_data(year, month)
    sheet_events = vol_tab_controller(year, month).read_events()
    airtable_events = VolunteerAirtableController.read_events_for_month(year, month)
    modified_events = sheet_events.changed_events(airtable_events)
    modified_events.each { |e| puts(e) }
    VolunteerAirtableController.update_events(modified_events)

  end

  def populate_night_manager_sheet(year, month)
    tab_controller = night_manager_tab_controller(year, month)
    tab_events = tab_controller.read_events()
    airtable_events = NightManagerAirtableController.read_events_for_month(year, month)
    if airtable_events.num_events > tab_events.num_events
      puts("Adding missing events")
      tab_controller.replace_events(airtable_events)
    end
  end

  def update_airtable_night_manager_data(year, month)
    tab_controller = night_manager_tab_controller(year, month)
    tab_events = tab_controller.read_events()
    airtable_events = NightManagerAirtableController.read_events_for_month(year, month)
    modified_events = tab_events.changed_events(airtable_events)
    NightManagerAirtableController.update_events(modified_events)

  end

end

def sync_personnel_data(year, month)
  controller = Controller.new()
  controller.populate_vol_sheet(year, month)
  controller.update_airtable_personnel_data(year, month)
end

def populate_new_event_table(year, month)
  EventTable.populate_for_date_range(
    Date.new(year, month, 1),
    Date.new(year, month, -1)
  )
end

def populate_night_manager_sheet(year, month)
  controller = Controller.new()
  controller.populate_night_manager_sheet(year, month)
  controller.update_airtable_night_manager_data(year, month)
end

#populate_new_event_table(2021, 10)

#sync_personnel_data(2021, 10)

populate_night_manager_sheet(2021, 10)
