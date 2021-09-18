require 'date'

class TabController
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

  def initialize(wb_controller, tab_name)
    @wb_controller = wb_controller
    @tab_name = tab_name
    @sheet_id = @wb_controller.tab_ids_by_name()[tab_name]
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
    @wb_controller.apply_requests(
      [
        update_all_cells_request("userEnteredValue"),
        update_all_cells_request("userEnteredFormat")
      ]
    )
  end

  def self.tab_name_for_month(year, month)
    return Date.new(year, month, 1).strftime("%B %y")
  end
end
