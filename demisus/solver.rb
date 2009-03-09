require 'set'
require 'demisus/board'

module Demisus
  class SudokuSolver
    attr_reader :board

    # Class methods ==========================================================

    # Defines a new sudoku solving rule. The type must be one of:
    #
    # - :cell_group
    # - :region
    #
    # The name is the name of the rule, description is a description of what it
    # does, and the associated block is the code for the rule. The block will
    # receive an Array of SudokuCell objects comprising the cell_group or the
    # region currently being processed.
    def self.define_rule(type, name, description, &blk)
      raise NotImplementedError
    end

    # Instance methods =======================================================

    # Creates a new solver object for the given board (a matrix of Integer
    # objects; nil for the unknown numbers)
    def initialize(numbers)
      @board = SudokuBoard.new(numbers)
    end

    # Checks that the board to solve is consistent (doesn't have repeated
    # numbers so it's potentially solvable)
    def consistent?
      ret = true
      # Check every row first
      @board.cells.each do |row|
        row_numbers = Set.new
        row.each do |cell|
          n = cell.number
          if n and row_numbers.include? n
            ret = false
          end
          row_numbers << n
        end
      end
      # Check every column
      0.upto(@board.side_size-1) do |col|
        col_numbers = Set.new
        @board.cells.each do |row|
          n = row[col].number
          if n and col_numbers.include? n
            ret = false
          end
          col_numbers << n
        end
      end
      return ret
    end

    # Ensures the consistency of the board. It raises an
    # InconsistentSudokuError exception if it's not consistent, or does nothing
    # otherwise
    def ensure_consistency!
      if not consistent?
        raise InconsistentSudokuError, "Inconsistent sudoku, can't solve"
      end
    end

    def number_unsolved_cells
      @board.unsolved_cells.size
    end

    # Executes rules until the first change in the board (candidate removal or
    # number finding)
    def simplify!
      raise NotImplementedError
    end

    # Solves the whole sudoku. Raises the exception UnsolvableSudoku if it
    # can't be solved with the currently defined rules, or
    # InconsistentSudokuError if the sudoku is found to be inconsistent and
    # can't be solved at all
    def solve!
      raise NotImplementedError
    end
  end
end
