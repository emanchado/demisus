require 'set'
require 'demisus/board'

module Demisus
  class SudokuSolver
    attr_reader :board

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
    def self.define_rule(type, id, name, description, &blk)
      self.rules << {:type        => type,
                     :id          => id,
                     :name        => name,
                     :description => description,
                     :action      => blk}
    end

    define_rule(:cell_group,
                :final_numbers,
                "Final numbers remove candidates",
                "Every final number in a row/column/region automatically
                removes that number as candidate from the rest of the
                row/column/region") do |cells|
      solved, unsolved = cells.partition {|c| c.solved?}
      final_numbers = solved.map {|c| c.number}
      unsolved.each do |cell|
        common = cell.candidates & final_numbers
        if not common.empty?
          common.each do |c|
            cell.remove_candidate(c)
          end
        end
      end
    end

    # Instance methods =======================================================

    # Creates a new solver object for the given board (a matrix of Integer
    # objects; nil for the unknown numbers)
    def initialize(numbers)
      @board = SudokuBoard.new(numbers)
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

    def execute_rule(rule, cell_group)
      rule[:action].call(cell_group)
    end

    # Executes rules until the first change in the board (candidate removal or
    # number finding)
    def simplify!
      $stderr.puts "Simplifying by rows"
      @board.each_row do |row|
        rules(:cell_group).each do |rule|
          execute_rule(rule, row)
        end
      end
      $stderr.puts "Simplifying by columns"
      @board.each_column do |col|
        rules(:cell_group).each do |rule|
          execute_rule(rule, col)
        end
      end
      $stderr.puts "Simplifying by regions"
      @board.each_region do |region|
        rules(:cell_group).each do |rule|
          execute_rule(rule, region)
        end
      end
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
