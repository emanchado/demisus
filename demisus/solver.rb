require 'set'
require 'demisus/board'

module Demisus
  class UnsolvableSudokuError < StandardError; end

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

    define_rule(:cell_group,
                :naked_pairs,
                "Pair of cells with same candidates discard those for the rest",
                "A pair of cells having the same pair of candidates as only
                possibilities discard those candidates from the rest of the
                row/column/region") do |cells|
      unsolved = cells.find_all {|c| not c.solved?}
      # First, look for a pair of cells having the same pair of candidates
      candidate_groups_found = {}
      unsolved.each do |cell|
        cands = cell.candidates
        if cands.size == 2
          key = cands.sort.join("|")
          candidate_groups_found[key] ||= []
          candidate_groups_found[key] << cell
        end
      end
      # Now, if found, drop candidates from the rest of the cells
      candidate_groups_found.each_pair do |serial_cands,found_cells|
        raise InconsistentSudokuError if found_cells.size > 2
        next                          if found_cells.size < 2
        cells.each do |cell|
          next if found_cells.include? cell
          cands_to_remove = serial_cands.split("|").map {|i| i.to_i}
          (cands_to_remove & cell.candidates).each do |cand|
            cell.remove_candidate(cand)
          end
        end
      end
    end

    define_rule(:cell_group,
                :single_place_candidate,
                "A candidate is the solution for the only cell having it",
                "A candidate that appears in a single cell inside a group must
                be the solution for that cell") do |cells|
      # Collect, for each possible candidate, which cells consider it. Also
      # count the final numbers, to avoid assigning already existing final
      # numbers
      cells_for_candidate = {}
      cells.each do |cell|
        cell.candidates.each do |cand|
          cells_for_candidate[cand] ||= []
          cells_for_candidate[cand] << cell
        end
      end
      # Now, if some candidate has a single cell, set that candidate as
      # solution for the cell
      cells_for_candidate.each_pair do |cand, cells|
        if cells.size == 1
          cells.first.number = cand
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

    def execute_rule(rule, cell_group)
      $stderr.puts "Calling rule #{rule[:id]}"
      rule[:action].call(cell_group)
      ensure_consistency!
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
