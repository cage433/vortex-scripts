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

  def update_vol_sheet_from_airtable(year, month, force)
    tab_controller = vol_tab_controller(year, month)
    airtable_events_personnel = VolunteerAirtableController.read_events_personnel(year, month)
    sheet_events_personnel = tab_controller.read_events_personnel()
    events_personnel = EventsPersonnel.new(
      events_personnel: sheet_events_personnel.events_personnel.collect { |ep|
        if airtable_events_personnel.include?(ep.airtable_id)
          ap = airtable_events_personnel[ep.airtable_id]
          if ep.metadata_match(ap)
            ep
          else
            ep.with_metadata_from(ap)
          end
        else
          ep
        end
      }
    )
    events_personnel = events_personnel.add_missing(airtable_events_personnel)
    if !events_personnel.matches(sheet_events_personnel) || force
      puts("Updating vol sheet")
      tab_controller.replace_events(events_personnel)
    end
  end

  def update_airtable_from_vol_sheet(year, month, force)
    sheet_events = vol_tab_controller(year, month).read_events_personnel()
    if force
      VolunteerAirtableController.update_events_personnel(sheet_events)
    else
      airtable_events = VolunteerAirtableController.read_events_personnel(year, month)
      modified_events = sheet_events.changed_personnel(airtable_events)
      VolunteerAirtableController.update_events_personnel(modified_events)
    end

  end

  def update_nm_tab_from_airtable(year, month, force)
    # Add new events and update any modified prices
    tab_controller = night_manager_tab_controller(year, month)
    original_events = tab_controller.read_events()

    events = tab_controller.read_events()
    airtable_events = NightManagerAirtableController.read_events_for_month(year, month)
    events = airtable_events.diff_by_date(events) + events

    airtable_events.data.each { |a|
      e = events[a.date]
      e.update_gig1_ticket_price(a.gig1_takings.ticket_price)
      e.update_gig2_ticket_price(a.gig2_takings.ticket_price)
      e.update_fee_details(a.fee_details)
    }

    if events != original_events || force
      tab_controller.replace_events(events)
    end

  end

  def update_airtable_from_nm_tab(year, month, force)
    tab_controller = night_manager_tab_controller(year, month)
    tab_events = tab_controller.read_events()
    if force
      NightManagerAirtableController.update_events(tab_events.data)
    else
      airtable_events = NightManagerAirtableController.read_events_for_month(year, month)
      modified_events = tab_events.changed_data(airtable_events)
      NightManagerAirtableController.update_events(modified_events.data)
    end
  end
end

def sync_personnel_data(year, month, force = false)
  controller = Controller.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end

def populate_new_event_table(year, month)
  EventTable.populate_for_date_range(
    Date.new(year, month, 1),
    Date.new(year, month, -1)
  )
end

def sync_night_manager_data(year, month, force = false)
  controller = Controller.new()
  controller.update_nm_tab_from_airtable(year, month, force)
  controller.update_airtable_from_nm_tab(year, month, force)
end

#populate_new_event_table(2021, 10)

sync_personnel_data(2021, 10, force=false)

#sync_night_manager_data(2021, 10, force=false)
