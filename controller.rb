require_relative 'google-sheets/workbook_controller.rb'
require_relative 'google-sheets/volunteer_tab_controller.rb'
require_relative 'env'
require_relative 'airtable/volunteer_controller'
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
end


def sync_personnel_data(year, month, force = false)
  controller = Controller.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end


sync_personnel_data(2021, 11, force=false)

