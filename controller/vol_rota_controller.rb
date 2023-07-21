require_relative '../airtable/vol_rota_airtable'
require_relative '../google-sheets/vol_rota_tab_controller'
require_relative '../logging.rb'

class VolRotaController

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
      events_personnel: sheet_events_personnel.events_personnel.select { |ep|
        airtable_events_personnel.include?(ep.airtable_id)
      }.collect { |ep|
        ap = airtable_events_personnel[ep.airtable_id]
        if ep.airtable_data_matches(ap)
          ep
        else
          ep.updated_from_airtable(ap)
        end
      }
    )
    events_personnel = events_personnel.add_missing(airtable_events_personnel)
    if !events_personnel.vol_rota_data_matches(sheet_events_personnel) || force
      LOG.info("Updating vol sheet")
      tab_controller.replace_events(events_personnel)
    end
  end

  def update_airtable_from_vol_sheet(year, month, force)
    sheet_events = vol_tab_controller(year, month).read_events_personnel()
    if force
      VolunteerAirtableController.update_events_personnel(sheet_events)
    else
      airtable_events = VolunteerAirtableController.read_events_personnel(year, month)
      modified_events = sheet_events.changed_vol_rota_data(airtable_events)
      VolunteerAirtableController.update_events_personnel(modified_events)
    end

  end
end

