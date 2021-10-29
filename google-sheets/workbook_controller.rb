require_relative 'sheets-service'

class WorkbookController
  def initialize(workbook_id)
    @service = get_sheets_service()
    @workbook_id = workbook_id
  end

  def tab_ids_by_name()
    ids_by_name = {}
    workbook = @service.get_spreadsheet(@workbook_id)
    workbook.sheets.each_with_index do |sheet, i|
      ids_by_name[sheet.properties.title] = sheet.properties.sheet_id
    end
    ids_by_name
  end

  def has_tab_with_name?(name)
    tab_ids_by_name().has_key?(name)
  end

  def apply_request(request)
		result = @service.batch_update_spreadsheet(
		  @workbook_id, 
		  {requests: [request]},
		  fields: nil, quota_user: nil, options: nil
      
		)
  end

  def apply_requests(requests)
		result = @service.batch_update_spreadsheet(
		  @workbook_id, 
		  {requests: requests},
		  fields: nil,
		  quota_user: nil,
		  options: nil
		)
  end

  def add_tab(name)
    raise "Sheet called #{name} already exists" if has_tab_with_name?(name)
    request = {
      add_sheet: {
        properties: {
          title: name,
          grid_properties: {hide_gridlines: true}
        }
      }
    }
    apply_request(request)
    puts("Created sheet for #{name}")
  end

  def set_data(range, data)
    raise "Dimension mismatch, range rows #{range.num_rows}, data #{data.size}" if range.num_rows != data.size
    raise "Dimension mismatch, range cols #{range.num_cols}, data #{data[0].size}" if range.num_cols != data[0].size

    value_range = range.as_value_range()
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: value_range, values: data)
    result = @service.update_spreadsheet_value(@workbook_id,
                                              value_range,
                                              value_range_object,
                                              value_input_option: "USER_ENTERED")
  end

  def get_spreadsheet_values(range)
    @service.get_spreadsheet_values(@workbook_id, range.as_value_range()).values
  end
end
