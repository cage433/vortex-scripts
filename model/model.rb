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

class EventDetails
  attr_reader :event_date, :event_title, :personnel
  def initialize(event_date, event_title, personnel)
    @event_date = event_date
    @event_title = event_title
    @personnel = personnel
  end

end
