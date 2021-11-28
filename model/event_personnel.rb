require_relative '../utils/utils'

class EventPersonnel 
  attr_reader :airtable_id, :title, :date, :doors_open, :vol1, :vol2, :night_manager, :sound_engineer

  def initialize(airtable_id:, title:, date:, doors_open:, vol1:, vol2:, night_manager:, sound_engineer:)
    assert_type(doors_open, Time, allow_null: true)
    @airtable_id = airtable_id
    @title = title
    @date = date
    @doors_open = doors_open
    @vol1 = vol1
    @vol2 = vol2
    @night_manager = night_manager
    @sound_engineer = sound_engineer
  end

  #def state
    #[@airtable_id, @title, @date, @doors_open, @vol1, @vol2, @night_manager, @sound_engineer]
  #end

  def to_s_table(indent)
    [
      "Title:           #{@title}",
      "Date:            #{@date}",
      "Doors:           #{@doors_open}",
      "Vol1:            #{@vol1}",
      "Vol2:            #{@vol2}",
      "NM:              #{@night_manager}",
      "SE:              #{@sound_engineer}",
    ].collect { |t| "#{indent}#{t}" }
  end

  def to_s()
    to_s_table("")
  end

  def personnel_match(rhs)
    raise "Mismatching ids" unless airtable_id == rhs.airtable_id
    EventPersonnel.states_match(personnel_state, rhs.personnel_state)
  end

  def metadata_match(rhs)
    EventPersonnel.states_match(metadata_state, rhs.metadata_state)
  end

  def state
    [@title, @date, @doors_open, @vol1, @vol2, @night_manager, @sound_engineer, @sound_engineer]
  end

  def matches(rhs)
    EventPersonnel.states_match(state, rhs.state)
  end

  def personnel_state
    [@vol1, @vol2, @night_manager, @sound_engineer]
  end

  def metadata_state
    [@title, @date, @doors_open, @sound_engineer]
  end

  def with_metadata_from(rhs)
    EventPersonnel.new(
      airtable_id:    @airtable_id,
      title:          rhs.title,
      date:           rhs.date, 
      doors_open:     rhs.doors_open,
      vol1:           @vol1,
      vol2:           @vo2,
      night_manager:  @night_manager,
      sound_engineer: rhs.sound_engineer
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
    @events_personnel_by_id = Hash[ *events_personnel.collect { |e| [e.airtable_id, e ] }.flatten ]
    @airtable_ids = events_personnel.collect{ |p| p.airtable_id }.sort
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

  def changed_personnel(rhs)
    assert_type(rhs, EventsPersonnel)
    EventsPersonnel.new(
      events_personnel: @events_personnel.filter { |ep| !ep.personnel_match(rhs[ep.airtable_id]) }
    )
  end

  def matches(rhs)
    assert_type(rhs, EventsPersonnel)
    if @airtable_ids != rhs.airtable_ids
      false
    else 
      @airtable_ids.all? { |id| @events_personnel_by_id[id].matches(rhs[id])}
    end
  end
end
