require 'date'
require_relative 'sheet-range'

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

  def initialize(wb_controller, tab_name)
    @wb_controller = wb_controller
    @tab_name = tab_name
    @sheet_id = @wb_controller.tab_ids_by_name()[tab_name]
  end

  def single_column_range(col)
    SheetRange.new(nil, nil, col, col + 1, @sheet_id, @tab_name)
  end




  def sheet_range(
    start_row_index, 
    end_row_index, 
    start_column_index = 0, 
    end_column_index = @width
  )
    SheetRange.new(start_row_index, end_row_index, start_column_index, end_column_index, @sheet_id, @tab_name)
  end

  def sheet_range_from_coordinates(coordinates)
    top_left, bottom_right = coordinates.upcase.split(":")
    start_row_index = top_left[0].ord - "A".ord
    start_col_index = top_left[1..].to_i - 1
    end_row_index = bottom_right[0].ord - "A".ord + 1
    end_col_index = bottom_right[1..].to_i 
    sheet_range(start_row_index, end_row_index, start_col_index, end_col_index)
  end

  def sheet_row(
    row_index,
    start_column_index,
    end_column_index
  )
    sheet_range(row_index, row_index + 1, start_column_index, end_column_index)
  end

  def sheet_cell(row_index, column_index)
    sheet_range(row_index, row_index + 1, column_index, column_index + 1)
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

  def set_left_right_border_request(range, style: "SOLID", color: @@black)
    border_style = {
          style: style,
          color: color
    }

    {
      update_borders: {
        range: range.as_json_range(),
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

  def horizontal_alignment_request(range, align)
      {
        repeat_cell: {
          range: range.as_json_range(),
          cell: {
            user_entered_format: {
              horizontal_alignment: "#{align}"
            }
          },
          fields: "user_entered_format.horizontal_alignment"
        }
      }
  end

  def center_text_request(range)
    horizontal_alignment_request(range, "CENTER")
  end

  def right_align_text_request(range)
    horizontal_alignment_request(range, "RIGHT")
  end

  def text_format_request(range, format)
      {
        repeat_cell: {
          range: range.as_json_range(),
          cell: {
            user_entered_format: {
              text_format: format
            }
          },
          fields: "user_entered_format.text_format"
        }
      }
  end
  def bold_text_request(range)
      {
        repeat_cell: {
          range: range.as_json_range(),
          cell: {
            user_entered_format: {
              text_format: {
                bold: true
              }
            }
          },
          fields: "user_entered_format.text_format"
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
        update_all_cells_request("userEnteredFormat")
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
