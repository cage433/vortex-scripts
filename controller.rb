require_relative 'google-sheets/workbook_controller.rb'
require_relative 'google-sheets/volunteer_tab_controller.rb'
require_relative 'google-sheets/night_manager_tab_controller.rb'
require_relative 'env'
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

  def populate_vol_sheet(year, month, force)
    tab_controller = vol_tab_controller(year, month)
    sheet_events = tab_controller.read_events()
    airtable_events = VolunteerAirtableController.read_events_for_month(year, month)
    merged_events = sheet_events.merge(airtable_events)
    if merged_events.num_events > sheet_events.num_events || force
      puts("Adding missing events")
      tab_controller.replace_events(merged_events)
    end
  end

  def update_airtable_personnel_data(year, month, force)
    sheet_events = vol_tab_controller(year, month).read_events()
    if force
      VolunteerAirtableController.update_events(sheet_events.events)
    else
      airtable_events = VolunteerAirtableController.read_events_for_month(year, month)
      modified_events = sheet_events.changed_events(airtable_events)
      VolunteerAirtableController.update_events(modified_events.events)
    end

  end

  def update_nm_tab_from_airtable(year, month)
    # Add new events and update any modified prices
    tab_controller = night_manager_tab_controller(year, month)
    original_events = tab_controller.read_events()

    events = tab_controller.read_events()
    airtable_events = NightManagerAirtableController.read_events_for_month(year, month)
    events = airtable_events.diff_by_date(events) + events

    airtable_events.events.each { |a|
      e = events.event_for_date(a.date)
      e.update_gig1_ticket_price(a.gig1_takings.ticket_price)
      e.update_gig2_ticket_price(a.gig2_takings.ticket_price)
      e.update_fee_details(a.fee_details)
    }

    if events != original_events
      tab_controller.replace_events(events)
    end

  end

  def update_airtable_from_nm_tab(year, month)
    tab_controller = night_manager_tab_controller(year, month)
    tab_events = tab_controller.read_events()
    airtable_events = NightManagerAirtableController.read_events_for_month(year, month)
    modified_events = tab_events.changed_events(airtable_events)
    if modified_events.num_events > 0
      puts("Updating airtable")
      NightManagerAirtableController.update_events(modified_events.events)
    end
  end
end

def sync_personnel_data(year, month, force = false)
  controller = Controller.new()
  controller.populate_vol_sheet(year, month, force)
  controller.update_airtable_personnel_data(year, month, force)
end

def populate_new_contract_table(year, month)
  ContractTable.populate_for_date_range(
    Date.new(year, month, 1),
    Date.new(year, month, -1)
  )
end

def sync_night_manager_data(year, month)
  controller = Controller.new()
  controller.update_nm_tab_from_airtable(year, month)
  controller.update_airtable_from_nm_tab(year, month)
end

#populate_new_contract_table(2021, 10)

sync_personnel_data(2021, 10, force=true)

#sync_night_manager_data(2021, 10)
