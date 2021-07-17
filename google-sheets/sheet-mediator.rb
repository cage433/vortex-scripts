class SheetMediator
  @@light_green = {
      red: 0.9,
      green: 1.0,
      blue: 0.9,
  }
  @@black = {
      red: 0.0,
      green: 0.0,
      blue: 0.0,
  }

  def initialize(service, spreadsheet_id, sheet_name, sheet_id)
    @service = service
    @sheet_name = sheet_name
    @spreadsheet_id = spreadsheet_id
    @sheet_id = sheet_id
  end

  def set_data(range, data)
    raise "Dimension mismatch, range rows #{range.num_rows}, data #{data.size}" if range.num_rows != data.size
    raise "Dimension mismatch, range cols #{range.num_cols}, data #{data[0].size}" if range.num_cols != data[0].size

    value_range = range.as_value_range()
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: value_range, values: data)
    result = @service.update_spreadsheet_value(@spreadsheet_id,
                                              value_range,
                                              value_range_object,
                                              value_input_option: "USER_ENTERED")
  end

  def set_background_color_request(range, color_json)
    {
      repeat_cell: {
        range: range.as_json_range(),
        cell: {
          user_entered_format: {
            background_color: color_json
          }
        },
        fields: "user_entered_format.background_color"
      }
    }
  end

  def set_number_format_request(range, format)
    {
      repeat_cell: {
        range: range.as_json_range(),
        cell: {
          user_entered_format: {
            number_format: {
              type: "DATE",
              pattern: format
            }
          }
        },
        fields: "user_entered_format.number_format"
      }
    }
  end


  def set_outside_border_request(range, style: "SOLID_MEDIUM", color: @@black)
    border_style = {
          style: style,
          color: color
    }

    {
      update_borders: {
        range: range.as_json_range(),
        top: border_style,
        bottom: border_style,
        left: border_style,
        right: border_style
      }
    }
  end

  def set_column_width_request(i_col, width)
    {
      update_dimension_properties: {
        range: {
          sheet_id: @sheet_id,
          dimension: "COLUMNS",
          start_index: i_col,
          end_index: i_col + 1
        },
        properties: {
          pixel_size: width
        },
        fields: "pixel_size"
      }
    }
  end

  def apply_requests(requests)
		result = @service.batch_update_spreadsheet(
		  @spreadsheet_id, 
		  {requests: requests},
		  fields: nil,
		  quota_user: nil,
		  options: nil
		)
  end

  def update_all_cells_request(fields)
    {
      update_cells: {
        range: {
          sheet_id: @sheet_id
        },
        fields: fields
      }
    }
  end

  def clear_values()
    apply_requests(
      [
        update_all_cells_request("userEnteredValue"),
        update_all_cells_request("userEnteredFormat")
      ]
    )
  end
end
