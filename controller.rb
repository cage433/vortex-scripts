require_relative 'google-sheets/volunteer-sheets'
require_relative 'google-sheets/volunteer-sheet/mediator.rb'
require_relative 'env'
require_relative 'airtable/events-table'
require 'date'

class Controller
  def events_for_month(year, month)
    events = AlexEvents.records_for_month(year, month).collect do |rec|
      EventMediator.from_airtable_record(rec)
    end
    EventsForMonth.new(year, month, events)
  end
end

def populate_vol_sheet(year, month)
  controller = Controller.new()
  airtable_events = controller.events_for_month(year, month)
  rota_mediator = VolunteerSpreadsheetMediator.new(VOL_ROTA_SPREADSHEET_ID)
  if !rota_mediator.has_sheet_for_month?(year, month)
    rota_mediator.add_sheet_for_month(year, month)
  end
  month_mediator = rota_mediator.month_sheet_medtiator(year, month)
  sheet_events = month_mediator.read_events_from_sheet()
  merged_events = sheet_events.merge(airtable_events)
  if merged_events.num_events > sheet_events.num_events
    puts("Adding missing events")
    month_mediator.clear_values()
    month_mediator.write_header()
    month_mediator.write_events(merged_events)
  end
end

def populate_night_manager_table(year, month)
  airtable_events = AlexEventRecords.new(AlexEvents.events_for_month(year, month))
  events = AlexEvents.events_for_month(2021, 9)
  event_record_ids = airtable_events.collect do |e|
    e.record_id
  end
  night_manager_record_ids = NightManagerTable.all_event_record_ids()
  events.each do |e|
    if !night_manager_record_ids.include?(e.record_id)
      puts("Creating record for #{e.event_title}")
      NightManagerTable.create("Alex Events" => [e.record_id], "Gig Code" => e.gig_code)
    end
  end

end

#populate_night_manager_table(2021, 10)
populate_vol_sheet(2021, 10)
