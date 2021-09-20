
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
end

