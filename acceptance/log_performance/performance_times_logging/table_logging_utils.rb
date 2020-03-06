class RangeInTable
  attr_accessor :start_column, :start_row, :end_column, :end_row

  def initialize(start_column, start_row, end_column, end_row)
    @start_column = start_column
    @start_row = start_row
    @end_column = end_column
    @end_row = end_row
  end
end

module ConditionRule
  GREATER_THAN = {type: 'CUSTOM_FORMULA', values: '=GT(%<compared_with>s, %<compared>s)'}.freeze

  def self.greater_than(value, start_position)
    rule = {type: GREATER_THAN[:type]}
    rule[:values] = format(GREATER_THAN[:values], compared: value, compared_with: A1Notation.convert_start_position(start_position))
    rule
  end
end

class Color
  attr_accessor :red, :green, :blue

  def initialize(red = 0, green = 0, blue = 0)
    @red = red
    @green = green
    @blue = blue
  end

  def code
    {red: @red, blue: @blue, green: @green}
  end
end

module A1Notation
  #In A1 notation row values start from 1, so we'll add a 1 to row values
  COLUMN_LETTERS = ('A'..'ZZ').to_a

  def self.convert_start_position(range)
    "#{COLUMN_LETTERS[range.start_column]}#{range.start_row + 1}"
  end

  def self.convert_to_a1_notation(range)
    end_column = if range.end_column.nil? or range.end_column == ''
                   ''
                 else
                   COLUMN_LETTERS[range.end_column]
                 end
    RangeInTable.new(COLUMN_LETTERS[range.start_column],
                     range.start_row + 1,
                     end_column,
                     range.end_row + 1)
  end
end