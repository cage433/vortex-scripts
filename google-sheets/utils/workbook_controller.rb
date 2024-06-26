require_relative 'sheets_service'

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

  def get_row_groups(sheet_id)
    workbook = @service.get_spreadsheet(@workbook_id)
    sheet = workbook.sheets.find { |s| s.properties.sheet_id == sheet_id }
    raise "Sheet #{sheet_id} not found" if sheet.nil?
    sheet.row_groups || []
  end

  def has_tab_with_name?(name)
    tab_ids_by_name().has_key?(name)
  end

  def apply_request(request)
    request_with_retries(
      lambda {
        @service.batch_update_spreadsheet(
          @workbook_id,
          { requests: [request] },
          fields: nil, quota_user: nil, options: nil
        )
      }
    )
  end

  def apply_requests(requests)
    request_with_retries(
      lambda {
        @service.batch_update_spreadsheet(
          @workbook_id,
          { requests: requests },
          fields: nil,
          quota_user: nil,
          options: nil
        )
      }
    )
  end

  def request_with_retries(request)
    num_tries = 5
    i_try = 0
    have_succeeded = false
    result = nil
    while i_try < num_tries && !have_succeeded
      begin
        result = request.yield
        have_succeeded = true
      rescue Exception => e
        puts(e)
        i_try += 1
        if i_try < num_tries
          puts("Will retry writing data")
          sleep 20
          retry
        end
      end
    end
    if have_succeeded
      result
    else
      raise "Failed to write data after several retries"
    end
  end

  def add_tab(name)
    raise "Sheet called #{name} already exists" if has_tab_with_name?(name)
    request = {
      add_sheet: {
        properties: {
          title: name,
          grid_properties: { hide_gridlines: true }
        }
      }
    }
    apply_request(request)
    puts("Created sheet for #{name}")
  end

  def set_data(range, data)
    if range.num_rows == 1 && range.num_cols == 1 && data.class != Array
      data = [[data]]
    elsif range.num_cols == 1 and data[0].class != Array
      data = data.collect { |d| [d] }
    elsif range.num_rows == 1 and data[0].class != Array
      data = [data]
    end
    raise "Dimension mismatch, range rows #{range.num_rows}, data #{data.size}" if range.num_rows != data.size
    raise "Dimension mismatch, range cols #{range.num_cols}, data #{data[0].size}" if range.num_cols != data[0].size

    value_range = range.as_value_range()
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: value_range, values: data)
    request_with_retries(
      lambda {
        @service.update_spreadsheet_value(@workbook_id,
                                          value_range,
                                          value_range_object,
                                          value_input_option: "USER_ENTERED")
      }
    )
  end

  def get_spreadsheet_values(range)
    request_with_retries(
      lambda {
        @service.get_spreadsheet_values(
          @workbook_id,
          range.as_value_range(),
          value_render_option: "UNFORMATTED_VALUE",
          date_time_render_option: "FORMATTED_STRING"
        ).values
      }
    )
  end

  def get_cell_value(cell)
    assert_type(cell, SheetRange)
    raise "Not a cell #{cell}" unless cell.is_cell?
    values = get_spreadsheet_values(cell)
    if values.nil?
      nil
    else
      values[0][0]
    end
  end
end
