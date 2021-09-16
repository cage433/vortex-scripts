class SetPersonnel
  attr_reader :night_manager, :first_volunteer, :second_volunteer
  def initialize(night_manager, first_volunteer, second_volunteer)
    @night_manager = night_manager
    @first_volunteer = first_volunteer
    @second_volunteer = second_volunteer
  end

  def self.empty
    SetPersonnel.new("", "", "")
  end

end

class GigPersonnel
  attr_reader :first_set_volunteer_data, :second_set_volunteer_data, :sound_engineer

  def initialize(first_set_volunteer_data:, second_set_volunteer_data:, sound_engineer:)
    @first_set_volunteer_data = first_set_volunteer_data
    @second_set_volunteer_data = second_set_volunteer_data
    @sound_engineer = sound_engineer
  end

  def self.empty
    GigPersonnel.new(
      first_set_volunteer_data: SetPersonnel.empty, 
      second_set_volunteer_data: SetPersonnel.empty, 
      sound_engineer: ""
    )
  end

end

class Event
  attr_reader :event_date, :event_title, :personnel
  def initialize(event_date, event_title, personnel)
    @event_date = event_date
    @event_title = event_title
    @personnel = personnel
  end
end

class EventsForMonth
  attr_reader :year, :month, :events, :num_events

  def initialize(year, month, events)
    @year = year
    @month = month
    @events = events
    @events_by_date = Hash[ *events.collect { |e| [e.event_date, e ] }.flatten ]
    @num_events = events.size

  end

  def sorted_events()
    @events.sort_by { |a| a.event_date}
  end


  def merge(rhs)
    merged_events = [*@events]
    rhs.events.each do |event|
      if !@events_by_date.has_key?(event.event_date)
        merged_events.push(event)
      end
    end
    EventsForMonth.new(@year, @month, merged_events)
  end
end
