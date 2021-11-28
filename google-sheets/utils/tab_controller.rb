require 'date'
require_relative 'sheet_range'

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
  @@light_yellow = {
      red: 1.0,
      green: 1.0,
      blue: 0.9,
  }
  @@yellow = {
      red: 1.0,
      green: 1.0,
      blue: 0.8,
  }
  @@almond = {
      red: 1.0,
      green: 0.9,
      blue: 0.8,
  }

  def initialize(wb_controller, tab_name)
    @wb_controller = wb_controller
    @tab_name = tab_name
    @sheet_id = @wb_controller.tab_ids_by_name()[tab_name]
  end

  def get_spreadsheet_values(range)
    @wb_controller.get_spreadsheet_values(range)
  end

  def single_column_range(col)
    SheetRange.new(
      SheetCell.from_row_and_col(0, col),
      nil,
      1,
      @sheet_id, @tab_name)
  end


  def sheet_range_from_coordinates(coordinates)
    top_left, bottom_right = coordinates.upcase.split(":")
    i_first_row = top_left[1..].to_i - 1
    i_first_col = top_left[0].ord - "A".ord
    i_last_row = bottom_right[1..].to_i - 1
    i_last_col = bottom_right[0].ord - "A".ord 
    SheetRange.new(
      SheetCell.from_coordinates(top_left), 
      i_last_row - i_first_row + 1,
      i_last_col - i_first_col + 1,
      @sheet_id,
      @tab_name
    )
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
            number_format: format
          }
        },
        fields: "user_entered_format.number_format"
      }
    }
  end

  def set_date_format_request(range, format)
    set_number_format_request(range, {type: "DATE", pattern: format})
  end
  def set_currency_format_request(range)
    set_number_format_request(range, {type: "CURRENCY"})
  end
  def set_percentage_format_request(range)
    set_number_format_request(range, {type: "PERCENT"})
  end

  def set_border_request(range, style: "SOLID_MEDIUM", color: @@black, borders:)
    border_style = {
          style: style,
          color: color
    }

    {
      update_borders: {range: range.as_json_range()}.merge(Hash[borders.collect{ |b| [b, border_style]}])
    }
  end

  def set_top_bottom_border_request(range, style: "SOLID", color: @@black)
    set_border_request(range, style: style, color: color, borders: [:top, :bottom])
  end

  def set_outside_border_request(range, style: "SOLID_MEDIUM", color: @@black)
    set_border_request(range, style: style, color: color, borders: [:left, :right, :top, :bottom])
  end

  def set_left_right_border_request(range, style: "SOLID", color: @@black)
    set_border_request(range, style: style, color: color, borders: [:left, :right])
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

  def hide_column_request(i_col, i_end_col = nil)
    {
      update_dimension_properties: {
        range: {
          sheet_id: @sheet_id,
          dimension: "COLUMNS",
          start_index: i_col,
          end_index: i_end_col || i_col + 1
        },
        properties: {
          hidden_by_user: true
        },
        fields: "hidden_by_user"
      }
    }
  end

  def user_entered_format_request(range, format)
    fields = format.keys.collect { |key| "user_entered_format.#{key}"}.join(",")
      {
        repeat_cell: {
          range: range.as_json_range(),
          cell: {
            user_entered_format: format
          },
          fields: fields
        }
      }
  end

  def horizontal_alignment_request(range, align)
    user_entered_format_request(range, {horizontal_alignment: "#{align}"})
  end

  def bold_and_center_request(range)
    user_entered_format_request(
      range,
      {
        horizontal_alignment: "CENTER", 
        text_format: {bold: true}
      }
    )
  end

  def center_text_request(range)
    horizontal_alignment_request(range, "CENTER")
  end

  def right_align_text_request(range)
    horizontal_alignment_request(range, "RIGHT")
  end

  def text_format_request(range, format)
    user_entered_format_request(range, {text_format: format})
  end

  def bold_text_request(range)
    text_format_request(range, {bold: true})
  end

  def create_checkbox_request(range)
      {
        repeat_cell: {
          range: range.as_json_range(),
          cell: {
            data_validation: {
              condition: {type: "BOOLEAN"},
              show_custom_ui: true
            }
          },
          fields: "data_validation"
        }
      }
  end
  def unmerge_all_request()
    {
      unmerge_cells: {
        range: {
          sheet_id: @sheet_id
        }
      }
    }
  end

  def merge_columns_request(range)
    {
      merge_cells: {
        merge_type: 'MERGE_ALL',
        range: range.as_json_range()
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

  def clear_values_and_formats()
    @wb_controller.apply_requests(
      [
        update_all_cells_request("userEnteredValue"),
        update_all_cells_request("userEnteredFormat"),
        unmerge_all_request()
      ]
    )
  end

  def clear_values(range)
    @wb_controller.apply_requests(
      [
        {
          update_cells: {
            range: range.as_json_range(),
            fields: "userEnteredValue"
          }
        }
      ]
    )
  end

  def self.tab_name_for_month(year, month)
    return Date.new(year, month, 1).strftime("%B %y")
  end

  def self.tab_name_for_date(date)
    return date.strftime("%-d %b %y")
  end
end
