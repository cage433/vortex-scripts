require_relative '../utils/utils'

class EventPersonnel
  attr_reader :airtable_id, :title, :date, :doors_open, :vol1, :vol2, :vol3, :night_manager, :sound_engineer, :member_bookings, :nm_notes

  def initialize(
    airtable_id:,
    title:, date:,
    doors_open:,
    vol1:, vol2:, vol3:,
    night_manager:, sound_engineer:,
    member_bookings:, nm_notes:
  )
    assert_type(doors_open, Time, allow_null: true)
    @airtable_id = airtable_id
    @title = title
    @date = date
    @doors_open = doors_open
    @vol1 = vol1
    @vol2 = vol2
    @vol3 = vol3
    @night_manager = night_manager
    @sound_engineer = sound_engineer
    @member_bookings = member_bookings
    @nm_notes = nm_notes
  end

  def to_s_table(indent)
    [
      "Title:           #{@title}",
      "Date:            #{@date}",
      "Doors:           #{@doors_open}",
      "Vol1:            #{@vol1}",
      "Vol2:            #{@vol2}",
      "Vol3:            #{@vol3}",
      "NM:              #{@night_manager}",
      "SE:              #{@sound_engineer}",
      "Mem Books:       #{@member_bookings}",
      "NM Notes:        #{@nm_notes}",
    ].collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("").join("\n")
  end

  def vol_rota_data_matches(rhs)
    raise "Mismatching ids" unless airtable_id == rhs.airtable_id
    EventPersonnel.states_match(data_from_vol_rota, rhs.data_from_vol_rota)
  end

  def airtable_data_matches(rhs)
    raise "Mismatching ids" unless airtable_id == rhs.airtable_id
    EventPersonnel.states_match(data_from_airtable, rhs.data_from_airtable)
  end

  def data_from_vol_rota
    [@vol1, @vol2, @vol3, @night_manager, @sound_engineer, @nm_notes, @member_bookings]
  end

  def data_from_airtable
    [@title, @date, @doors_open]
  end

  def updated_from_airtable(rhs)
    EventPersonnel.new(
      airtable_id: @airtable_id,
      title: rhs.title,
      date: rhs.date,
      doors_open: rhs.doors_open,
      vol1: @vol1,
      vol2: @vol2,
      vol3: @vol3,
      night_manager: @night_manager,
      sound_engineer: @sound_engineer,
      member_bookings: @member_bookings,
      nm_notes: @nm_notes
    )
  end

  def self.states_match(l, r)
    raise "State lengths differ" unless l.size == r.size
    l.zip(r).all? { |l, r|
      is_equal_ignoring_nil_or_blank?(l, r)
    }
  end
end

# A collection of EventPersonnel - exists to compare airtable and google sheets
# view of the world
class EventsPersonnel
  attr_reader :events_personnel, :airtable_ids

  def initialize(events_personnel:)
    assert_collection_type(events_personnel, EventPersonnel)
    @events_personnel = events_personnel
    @events_personnel_by_id = Hash[*events_personnel.collect { |e| [e.airtable_id, e] }.flatten]
    @airtable_ids = events_personnel.collect { |p| p.airtable_id }.sort
  end

  def [](id)
    @events_personnel_by_id[id]
  end

  def include?(id)
    @events_personnel_by_id.include?(id)
  end

  def add_missing(rhs)
    merged_events_personnel = [*@events_personnel]
    rhs.events_personnel.each do |ep|
      if !include?(ep.airtable_id)
        merged_events_personnel.push(ep)
      end
    end
    EventsPersonnel.new(events_personnel: merged_events_personnel)
  end

  def size
    @events_personnel.size
  end

  def changed_vol_rota_data(rhs)
    assert_type(rhs, EventsPersonnel)
    EventsPersonnel.new(
      events_personnel: @events_personnel.filter { |ep| !ep.vol_rota_data_matches(rhs[ep.airtable_id]) }
    )
  end

  def airtable_data_matches(rhs)
    assert_type(rhs, EventsPersonnel)
    if @airtable_ids != rhs.airtable_ids
      false
    else
      @airtable_ids.all? { |id| @events_personnel_by_id[id].airtable_data_matches(rhs[id]) }
    end
  end

  def vol_rota_data_matches(rhs)
    assert_type(rhs, EventsPersonnel)
    if @airtable_ids != rhs.airtable_ids
      false
    else
      @airtable_ids.all? { |id| @events_personnel_by_id[id].vol_rota_data_matches(rhs[id]) }
    end
  end
end
