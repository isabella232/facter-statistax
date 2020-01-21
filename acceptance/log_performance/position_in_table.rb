class PositionInTable
  attr_accessor :start_row, :start_column, :end_column, :end_row
  def initialize(start_column, start_row, end_column, end_row)
    @start_column = start_column
    @start_row = start_row
    @end_column = end_column
    @end_row = end_row
  end
end