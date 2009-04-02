require 'set'
require 'demisus/board'
require 'demisus/mixins/listeners'

module Demisus
  class UnsolvableSudokuError < StandardError; end

  class SudokuSolver
    attr_reader :board

    include Demisus::Mixins::Listeners

    def event_types; [:before_applying_rule,
                      :after_applying_rule]; end

    # Class methods ==========================================================

    def self.rules(type=:all)
      @rules ||= []
      case type
      when :all
        @rules
      else
        @rules.find_all {|r| r[:type] == type}
      end
    end

    def self.rule_by_id(id)
      @rules.find_all {|r| r[:id] == id}.first
    end

    # Defines a new sudoku solving rule. The type must be one of:
    #
    # - :cell_group
    # - :region
    #
    # The id is a symbol representing the rule. The name is a short name for
    # it, description is a description of what it does (say, a long sentence
    # or short paragraph), and the associated block is the code for the rule.
    # The block will receive an Array of SudokuCell objects comprising the
    # cell_group or the region currently being processed.
    #
    # The rules themselves are defined in 'demisus/rules' (see the end of the
    # file for the actual require)
    def self.define_rule(type, id, name, description, &blk)
      self.rules << {:type        => type,
                     :id          => id,
                     :name        => name,
                     :description => description,
                     :action      => blk}
    end

    # Instance methods =======================================================

    # Creates a new solver object for the given board (a matrix of Integer
    # objects; nil for the unknown numbers)
    def initialize(numbers)
      @board = SudokuBoard.new(numbers)
      @board.define_listener(:set_number) do |i,j,n|
        remove_obvious_candidates(i, j, n)
      end
      @removed_first_obvious_candidates = false
      initialize_listeners
    end

    def remove_obvious_candidates(i, j, n)
      # Remove obvious candidates every time we find a number
      row, column, region = @board.rows[i],
                            @board.columns[j],
                            @board.region_for(i,j)
      [row, column, region].each do |cells|
        cells.reject {|c| c.solved?}.each do |cell|
          if cell.candidates.include? n
            cell.remove_candidate(n)
          end
        end
      end
    end

    def rules(type)
      self.class.rules(type)
    end

    # Checks that the board to solve is consistent (doesn't have repeated
    # numbers so it's potentially solvable)
    def consistent?
      ret = true
      # Check every row first
      @board.each_row do |row|
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
      @board.each_column do |col|
        col_numbers = Set.new
        col.each do |cell|
          n = cell.number
          if n and col_numbers.include? n
            ret = false
          end
          col_numbers << n
        end
      end
      # Check every region
      @board.each_region do |reg|
        reg_numbers = Set.new
        reg.each do |cell|
          n = cell.number
          if n and reg_numbers.include? n
            ret = false
          end
          reg_numbers << n
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

    def execute_rule(rule, *params)
      call_listeners(:before_applying_rule, [rule])
      rule[:action].call(*params)
      call_listeners(:after_applying_rule, [rule])
      ensure_consistency!
    end

    # Executes rules until the first change in the board (candidate removal or
    # number finding)
    def simplify!
      # Ugly corner case: the first time we ever touch the board, it should be
      # to remove the obvious candidates (after the already solved cells). The
      # rest of the obvious candidates will only be removed on demand, every
      # time we solve a cell (see the listener in the constructor)
      unless @removed_first_obvious_candidates
        @board.each_cell do |cell|
          remove_obvious_candidates(cell.i, cell.j, cell.number)
        end
        @removed_first_obvious_candidates = true
      end

      @board.each_row do |row|
        rules(:cell_group).each do |rule|
          execute_rule(rule, row)
        end
      end
      @board.each_column do |col|
        rules(:cell_group).each do |rule|
          execute_rule(rule, col)
        end
      end
      @board.each_region do |region|
        rules(:cell_group).each do |rule|
          execute_rule(rule, region)
        end
      end
    end

    # Solves the whole sudoku. Raises the exception UnsolvableSudokuError if it
    # can't be solved with the currently defined rules, or
    # InconsistentSudokuError if the sudoku is found to be inconsistent and
    # can't be solved at all (has 0 solutions)
    def solve!
      number_unsolved_cells_before = number_unsolved_cells
      loop do
        simplify!
        unsolved = number_unsolved_cells
        if unsolved >= number_unsolved_cells_before
          raise UnsolvableSudokuError,
                "Can't solve sudoku (#{unsolved} cells left to solve)"
        end
        number_unsolved_cells_before = unsolved
        break if unsolved == 0
      end
    end
  end
end

require 'demisus/rules'
