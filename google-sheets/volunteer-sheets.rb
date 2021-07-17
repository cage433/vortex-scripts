require_relative 'sheets-service'
require_relative '../env'
require 'date'

class VolunteersForSet
  def initialize(night_manager, first_volunteer, second_volunteer)
    @night_manager = night_manager
    @first_volunteer = first_volunteer
    @second_volunteer = second_volunteer
  end
end

class GigPersonnel
  attr_reader :first_set_volunteer_data, :second_set_volunteer_data, :sound_engineer
  def initialize(first_set_volunteer_data, second_set_volunteer_data, sound_engineer)
    @first_set_volunteer_data = first_set_volunteer_data
    @second_set_volunteer_data = second_set_volunteer_data
    @sound_engineer = sound_engineer
  end
end

class VolunteerSheetGigDatum
  def initialize(event, personnel)
    @event = event
    @personnel = personnel
  end
end

class VolunteerSheetGigData
  @@header = ["Gigs", "Date", "Day", "Set No", "Doors Open", "Night Manager", "Vol 1", "Vol 2", "Sound Engineer"]
  def initialise(data)
    @data = data
  end

  def self.read_from_sheet(sheet_id)
    service = get_sheets_service()
    range = "Sheet1!A1:I100"
    response = service.get_spreadsheet_values sheet_id, range
    #response.values[1, 100].each do |row|
      #puts(row.join(", "))
    #end
  end

  def self.update_format(spreadsheet_id)
    service = get_sheets_service()
    request = {
      repeat_cell: {
        range: {
          start_row_index: 0,
          end_row_index: 1,
          start_column_index: 0,
          end_column_index: 9,
          sheet_id: 0
        },
        cell: {
          user_entered_format: {
            background_color: {
              red: 0.9,
              green: 1.0,
              blue: 0.9,
              alpha: 0.1
            }
          }
        },
        fields: "user_entered_format.background_color"
      }
    }
		# Add additional requests (operations) ...

		#result = service.batch_update_spreadsheet(sheet_id, body, {})
		result = service.batch_update_spreadsheet(
		  spreadsheet_id, 
		  {requests: [request]},
		  fields: nil,
		  quota_user: nil,
		  options: nil
		)
  end

  def self.sheet_name_for_month(year, month)
    return Date.new(year, month, 1).strftime("%B %y")
  end

  def self.sheet_id_for_month(spreadsheet_id, year, month)
    name_for_month = sheet_name_for_month(year, month)
    service = get_sheets_service()
    spreadsheet = service.get_spreadsheet(spreadsheet_id)
    sheets = spreadsheet.sheets
    sheet_id = nil
    sheets.each_with_index do |sheet, i|
      if sheet.properties.title == name_for_month
        sheet_id = i
      end
    end
    print("Sheet id #{sheet_id}")
    if sheet_id.nil?
      raise "Missing sheet name"
    end
    sheet_id
  end

  def self.report_sheet_names(spreadsheet_id)
    service = get_sheets_service()
    spreadsheet = service.get_spreadsheet(spreadsheet_id)
    sheets = spreadsheet.sheets
    sheets.each_with_index do |sheet|
      properties = sheet.properties
      puts(properties.title)
      puts(properties.sheet_id)
    end
  end

  def self.update_borders(spreadsheet_id)
    service = get_sheets_service()
    border_style = {
          style: "SOLID_MEDIUM",
          color: {
              red: 0.0,
              green: 0.0,
              blue: 0.0,
          }
    }

    request = {
      update_borders: {
        range: {
          start_row_index: 1,
          end_row_index: 3,
          start_column_index: 0,
          end_column_index: 9,
          sheet_id: 0
        },
        top: border_style,
        bottom: border_style,
        left: border_style,
        right: border_style
      }
    }
		result = service.batch_update_spreadsheet(
		  spreadsheet_id, 
		  {requests: [request]},
		  fields: nil,
		  quota_user: nil,
		  options: nil
		)
  end

  def self.write_events(spreadsheet_id, events)
    service = get_sheets_service()
    header_range = "September 21!A1:I1"

    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range:  header_range,
                                                                values: [@@header])
    result = service.update_spreadsheet_value(spreadsheet_id,
                                              header_range,
                                              value_range_object,
                                              value_input_option: "RAW")

		requests = []
    #Change the name of sheet ID '0' (the default first sheet on every spreadsheet)
    requests.push({
                    update_sheet_properties: {
                      properties: { sheet_id: 0, title: 'September 21' },
                      fields:     'title'
                    }
                  })
		## Find and replace text
		#requests.push({
										#find_replace: {
											#find:        "Gig",
											#replacement: "mid",
											#all_sheets:  true
										#}
									#})
    request2 = {
      repeat_cell: {
        range: {
          start_row_index: 0,
          end_row_index: 1,
          start_column_index: 0,
          end_column_index: 10,
          sheet_id: 0
        },
        cell: {
          user_entered_format: {
            background_color: {
              blue: 0.1,
              red: 0.9,
              green: 0.2,
              alpha: 0.1
            }
          }
        },
        fields: "user_entered_format.background_color"
      }
    }
		# Add additional requests (operations) ...
    #requests.push(request2)

		body = { requests: requests }
		#result = service.batch_update_spreadsheet(sheet_id, body, {})
		puts("Spreadsheet id #{spreadsheet_id}")
		result = service.batch_update_spreadsheet(
		  spreadsheet_id, 
		  body,
		  fields: nil,
		  quota_user: nil,
		  options: nil
      
			#body
		)
		#find_replace_response = result.replies[1].find_replace
		#puts "#{find_replace_response.occurrences_changed} replacements made."
  end
end

