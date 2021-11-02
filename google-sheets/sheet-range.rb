class SheetCell
  attr_reader :coordinates, :i_row, :i_col
  def initialize(coordinates, i_row, i_col)
    assert_type(coordinates, String)
    assert_collection_type([i_row, i_col], Integer)
    @coordinates = coordinates
    @i_row = i_row
    @i_col = i_col
  end

  def self.from_coordinates(coordinates)
    columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    i_col = columns.index(coordinates[0].upcase) || (raise "Unexpected coordinates #{coordinates}")
    i_row = coordinates[1..].to_i - 1
    SheetCell.new(coordinates, i_row, i_col)
  end

  def self.from_row_and_col(i_row, i_col)
    columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    column_name = columns[i_col] || (raise "Unexpected column #{i_col}")
    coordinates = "#{column_name}#{i_row + 1}"
    SheetCell.new(coordinates, i_row, i_col)
  end

  def offset(num_rows, num_cols)
    SheetCell.from_row_and_col(@i_row + num_rows, @i_col + num_cols)
  end
end

class SheetRange
  def initialize(
    top_left_cell,
    num_rows, num_cols,
    sheet_id,
    sheet_name
  )
    assert_type(top_left_cell, SheetCell)
    #assert_collection_type([num_rows, num_cols], Integer)
    @top_left_cell = top_left_cell
    @num_rows = num_rows
    @num_cols = num_cols
    @sheet_id = sheet_id
    @sheet_name = sheet_name
  end

  def bottom_right_cell
    @top_left_cell.offset(@num_rows - 1, @num_cols - 1)
  end

  def as_value_range()
    "#{@sheet_name}!#{@top_left_cell.coordinates}:#{bottom_right_cell.coordinates}"
  end

  def to_s
    "SheetRange: #{as_value_range}, rows #{@num_rows}, cols #{@num_cols}"
  end

  def is_cell?
    num_rows == 1 && num_cols == 1
  end

  def cell_reference()
    raise "Not a cell" if !is_cell?
    @top_left_cell.coordinates
  end

  def as_json_range()
    range = {
      start_row_index: @top_left_cell.i_row,
      start_column_index: @top_left_cell.i_col,
      sheet_id: @sheet_id
    }
    if !num_rows.nil?
      range[:end_row_index] = @top_left_cell.i_row + num_rows
    end
    if !num_cols.nil?
      range[:end_column_index] = @top_left_cell.i_col + num_cols
    end
    range
  end

  def num_cols 
    @num_cols
  end

  def num_rows
    @num_rows
  end

  def sub_range(relative_row_range: nil, relative_col_range: nil)
    rows(relative_row_range).columns(relative_row_range)
  end

  def column(col_no)
    columns(col_no)
  end

  def row(row_no)
    rows(row_no)
  end

  def _range_from_rangish(rangish, current_end)
    if rangish.nil?
      (0..current_end)
    elsif rangish.class == Integer
      rangish..rangish
    else 
      raise "Unexpected range #{rangish}" unless rangish.class == Range
      if rangish.begin.nil?
        if rangish.exclude_end?
          0..rangish.end - 1
        else
          0..rangish.end
        end
      elsif rangish.end.nil?
        rangish.begin..current_end
      else
        rangish
      end
    end
  end
  def _new_range(top_left_cell, num_rows, num_cols)
    SheetRange.new(top_left_cell, num_rows, num_cols, @sheet_id, @sheet_name)
  end

  def rows(rangish)
    range = _range_from_rangish(rangish, @num_rows - 1)
    _new_range(@top_left_cell.offset(range.begin, 0), range.to_a.size, @num_cols)
  end

  def columns(rangish)
    range = _range_from_rangish(rangish, @num_cols - 1)
    _new_range(@top_left_cell.offset(0, range.begin), @num_rows, range.to_a.size)
  end

  def is_row?
    @num_rows == 1
  end

  def is_column?
    @num_cols == 1
  end

  def cell(i, j = nil)
    if j.nil?
      if is_row?
        _cell(0, i)
      elsif is_column?
        _cell(i, 0)
      else
        raise "Not a single column or row range"
      end
    else
      _cell(i, j)
    end
  end

  def _cell(i_row, i_col)
    if i_row < 0
      _cell(num_rows + i_row, i_col)
    elsif i_col < 0
      _cell(i_row, num_cols + i_col)
    else
      _new_range(
        @top_left_cell.offset(i_row, i_col),
        1, 1
      )
    end
  end
end




#######################################################
# Old Version
# #####################################################
#class SheetRangeOld
  #def initialize(
    #start_row_index, 
    #end_row_index, 
    #start_column_index, 
    #end_column_index, 
    #sheet_id,
    #sheet_name
  #)
    #@start_row_index = start_row_index
    #@start_column_index = start_column_index
    #@end_row_index = end_row_index
    #@end_column_index = end_column_index
    #@sheet_id = sheet_id
    #@sheet_name = sheet_name
  #end

  #def as_value_range()
    #columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    #start_col_name = columns[@start_column_index] || (raise "Column #{@start_column_index} outside permitted range")
    #end_col_name = columns[@end_column_index - 1] || (raise "Column #{@end_column_index} outside permitted range")
    #"#{@sheet_name}!#{start_col_name}#{@start_row_index + 1}:#{end_col_name}#{@end_row_index}"
  #end

  #def is_cell?
    #num_rows == 1 && num_cols == 1
  #end

  #def cell_reference()
    #raise "Not a cell" if !is_cell?
    #columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    #col_name = columns[@start_column_index] || (raise "Column #{@start_column_index} outside permitted range")
    #"#{col_name}#{@start_row_index + 1}"
  #end

  #def as_json_range()
    #if @start_row_index.nil? && @end_row_index.nil?
      #{
          #start_column_index: @start_column_index,
          #end_column_index: @end_column_index,
          #sheet_id: @sheet_id
      #}
    #elsif @start_column_index.nil? && @end_column_index.nil?
      #{
          #start_row_index: @start_row_index,
          #end_row_index: @end_row_index,
          #sheet_id: @sheet_id
      #}
    #else
      #{
          #start_row_index: @start_row_index,
          #end_row_index: @end_row_index,
          #start_column_index: @start_column_index,
          #end_column_index: @end_column_index,
          #sheet_id: @sheet_id
      #}
    #end
  #end

  #def num_cols 
    #@end_column_index - @start_column_index
  #end

  #def num_rows
    #@end_row_index - @start_row_index
  #end

  #def add_row()
    #SheetRange.new(
      #@start_row_index, @end_row_index + 1, 
      #@start_column_index, @end_column_index, 
      #@sheet_id,
      #@sheet_name
    #)
  #end

  #def sub_range(row_range: nil, col_range: nil)
    #def new_indexes(rangish, start_index, end_index)
      #if rangish.nil?
        #[start_index, end_index]
      #else 
        #if rangish.class == Integer
          #rangish = (rangish..rangish)
        #end
        #if rangish.end.nil?
          #rangish = (rangish.first..end_index - start_index - 1)
        #end
        #[start_index + rangish.first, start_index + rangish.last + 1]
      #end
    #end
    #new_start_row, new_end_row = new_indexes(row_range, @start_row_index, @end_row_index)
    #new_start_col, new_end_col = new_indexes(col_range, @start_column_index, @end_column_index)
    #SheetRange.new(
      #new_start_row, new_end_row,
      #new_start_col, new_end_col,
      #@sheet_id, @sheet_name
    #)
  #end

  #def column(col_no)
    #if col_no < 0
      #column(num_cols + col_no)
    #else
      #sub_range(col_range: (col_no..col_no))
    #end
  #end

  #def row(row_no)
    #if row_no < 0
      #row(num_rows + row_no)
    #else
      #sub_range(row_range: (row_no..row_no))
    #end
  #end

  #def rows(range)
    #sub_range(row_range: range)
  #end

  #def columns(range)
    #sub_range(col_range: range)
  #end

  #def cell(i, j = nil)
    #if j.nil?
      #if num_rows == 1 && num_cols == 1 
        #_cell(i, i)
      #elsif num_rows == 1
        #_cell(0, i)
      #elsif num_cols == 1
        #_cell(i, 0)
      #else
        #raise "Not a single column or row range"
      #end
    #else
      #_cell(i, j)
    #end
  #end
  #def _cell(i_row, i_col)
    #if i_row < 0
      #_cell(num_rows + i_row, i_col)
    #elsif i_col < 0
      #_cell(i_row, num_cols + i_col)
    #else
      #SheetRange.new(
        #@start_row_index + i_row, @start_row_index + i_row + 1,
        #@start_column_index + i_col, @start_column_index + i_col + 1,
        #@sheet_id, @sheet_name
      #)
    #end
  #end
#end

