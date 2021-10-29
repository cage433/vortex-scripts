
class SheetRange
  def initialize(
    start_row_index, 
    end_row_index, 
    start_column_index, 
    end_column_index, 
    sheet_id,
    sheet_name
  )
    @start_row_index = start_row_index
    @start_column_index = start_column_index
    @end_row_index = end_row_index
    @end_column_index = end_column_index
    @sheet_id = sheet_id
    @sheet_name = sheet_name
  end

  def as_value_range()
    columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    start_col_name = columns[@start_column_index] || (raise "Column #{@start_column_index} outside permitted range")
    end_col_name = columns[@end_column_index - 1] || (raise "Column #{@end_column_index} outside permitted range")
    "#{@sheet_name}!#{start_col_name}#{@start_row_index + 1}:#{end_col_name}#{@end_row_index}"
  end

  def as_json_range()
    if @start_row_index.nil? && @end_row_index.nil?
      {
          start_column_index: @start_column_index,
          end_column_index: @end_column_index,
          sheet_id: @sheet_id
      }
    elsif @start_column_index.nil? && @end_column_index.nil?
      {
          start_row_index: @start_row_index,
          end_row_index: @end_row_index,
          sheet_id: @sheet_id
      }
    else
      {
          start_row_index: @start_row_index,
          end_row_index: @end_row_index,
          start_column_index: @start_column_index,
          end_column_index: @end_column_index,
          sheet_id: @sheet_id
      }
    end
  end

  def num_cols 
    @end_column_index - @start_column_index
  end

  def num_rows
    @end_row_index - @start_row_index
  end

  def add_row()
    SheetRange.new(
      @start_row_index, @end_row_index + 1, 
      @start_column_index, @end_column_index, 
      @sheet_id,
      @sheet_name
    )
  end

  def sub_range(row_range: nil, col_range: nil)
    def new_indexes(rangish, start_index, end_index)
      if rangish.nil?
        [start_index, end_index]
      else 
        if rangish.class == Integer
          rangish = (rangish..rangish)
        end
        if rangish.end.nil?
          rangish = (rangish.first..num_rows - 1)
        end
        [start_index + rangish.first, start_index + rangish.last + 1]
      end
    end
    new_start_row, new_end_row = new_indexes(row_range, @start_row_index, @end_row_index)
    new_start_col, new_end_col = new_indexes(col_range, @start_column_index, @end_column_index)
    SheetRange.new(
      new_start_row, new_end_row,
      new_start_col, new_end_col,
      @sheet_id, @sheet_name
    )
  end

  def column(col_no)
    sub_range(col_range: (col_no..col_no))
  end

  def row(row_no)
    sub_range(row_range: (row_no..row_no))
  end

  def cell(range_row, range_col)
    SheetRange.new(
      @start_row_index + range_row, @start_row_index + range_row + 1,
      @start_column_index + range_col, @start_column_index + range_col + 1,
      @sheet_id, @sheet_name
    )
  end
end

