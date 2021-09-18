require_relative 'google-sheets/workbook_controller.rb'
require_relative 'google-sheets/volunteer-sheet/controller.rb'
require_relative 'env'
require_relative 'airtable/event_table'
require 'date'

class Controller

  def initialize()
    @vol_rota_controller = WorkbookController.new(VOL_ROTA_SPREADSHEET_ID)
  end

  def airtable_events_for_month(year, month)
    ids = EventTable.ids_for_month(year, month)
    events = ids.collect { |id| 
      EventMediator.from_airtable(id) 
    }
    EventsForMonth.new(year, month, events)
  end

  def populate_vol_sheet(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    @vol_rota_controller.add_tab(tab_name) if !@vol_rota_controller.has_tab_with_name?(tab_name)
    tab_mediator = VolunteerMonthTabController.new(year, month, @vol_rota_controller)
    sheet_events = tab_mediator.read_events()
    merged_events = sheet_events.merge(airtable_events_for_month(year, month))
    if merged_events.num_events > sheet_events.num_events
      puts("Adding missing events")
      tab_mediator.replace_events(merged_events)
    end
  end

end

def populate_vol_sheet(year, month)
  controller = Controller.new()
  controller.populate_vol_sheet(year, month)
end

def populate_new_event_table(year, month)
  EventTable.populate_for_date_range(
    Date.new(year, month, 1),
    Date.new(year, month, -1)
  )

end

#populate_new_event_table(2021, 10)

populate_vol_sheet(2021, 10)
