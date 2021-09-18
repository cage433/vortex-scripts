require_relative 'google-sheets/workbook_controller.rb'
require_relative 'google-sheets/volunteer-sheet/controller.rb'
require_relative 'env'
require_relative 'airtable/events-table'
require 'date'

class Controller

  def initialize()
    @vol_rota_controller = WorkbookController.new(VOL_ROTA_SPREADSHEET_ID)
  end

  def airtable_events_for_month(year, month)
    events = AlexEvents.records_for_month(year, month).collect do |event_rec|
      gig_recs = Hash[
        event_rec[ALEX_GIGS].collect do |gig_id|
          gig_rec = AlexGigs.record_for_id(gig_id)
          [gig_rec[ALEX_GIG_TIME], gig_rec]
        end
      ]
      EventMediator.from_airtable_records(event_rec, gig_recs[ALEX_7_PM], gig_recs[ALEX_9_PM])
    end
    EventsForMonth.new(year, month, events)
  end

  def populate_vol_sheet(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    @vol_rota_controller.add_sheet(tab_name) if !@vol_rota_controller.has_tab_with_name?(tab_name)
    tab_mediator = VolunteerMonthTabController.new(year, month, @vol_rota_controller)
    sheet_events = tab_mediator.read_events()
    merged_events = sheet_events.merge(airtable_events_for_month(year, month))
    if merged_events.num_events > sheet_events.num_events
      puts("Adding missing events")
      tab_mediator.replace_events(merged_events)
    end
  end

  def update_airtable_vol_data(year, month)
    tab_name = TabController.tab_name_for_month(year, month)
    exit if !@vol_rota_controller.has_tab_with_name?(tab_name)

    tab_mediator = VolunteerMonthTabController.new(year, month, @vol_rota_controller)
    sheet_events = tab_mediator.read_events()
    airtable_events = Hash[airtable_events_for_month(year, month).events.collect { |e| [e.event_title, e] } ]
    sheet_events.events.each do |sheet_event| 
      puts()
      puts("Sheet")
      puts(sheet_event)
      if !airtable_events.has_key?(sheet_event.event_title) || airtable_events[sheet_event.event_title] != sheet_event
        AlexGigs.update_vol_data(event)
        puts("Airtable")
        ae = airtable_events[sheet_event.event_title]
        se1 = sheet_event.personnel.sound_engineer
        se2 = ae.personnel.sound_engineer
        puts(airtable_events[sheet_event.event_title])
      else
        puts("same")
      end
    end
    #event = sheet_events.events[0]
    #puts(event)
  end
end

def populate_vol_sheet(year, month)
  controller = Controller.new()
  controller.populate_vol_sheet(year, month)
end

def update_airtable_vol_data(year, month)
  controller = Controller.new()
  controller.update_airtable_vol_data(year, month)
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
#update_airtable_vol_data(2021, 10)
