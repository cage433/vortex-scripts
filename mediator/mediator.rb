
class SetPersonnelMediator
  def self.to_excel_data(personnel)
    [personnel.night_manager, personnel.first_volunteer, personnel.second_volunteer]
  end

  def self.from_excel(row)
    raise "Invalid dimension, length #{row.size}, expected 3" if row.size != 3
    SetPersonnel.new(row[0], row[1], row[2])
  end
end


class GigPersonnelMediator
  def self.to_excel_data(gig_personnel)
    [
      gig_personnel.first_set_volunteer_data.to_excel_data() + [gig_personnel.sound_engineer],
      gig_personnel.second_set_volunteer_data.to_excel_data() + [""]
    ]
  end

  def self.from_excel(rows)
    assert_dimension_2d(rows, 2, 4)
    sound_engineer = rows[0][3]
    first_set_volunteers = SetPersonnelMediator.from_excel(rows[0].slice(0, 3))
    second_set_volunteers = SetPersonnelMediator.from_excel(rows[1].slice(0, 3))
    GigPersonnel.new(
      first_set_volunteer_data: first_set_volunteers, 
      second_set_volunteer_data: second_set_volunteers,
      sound_engineer: sound_engineer
    )
  end
end
