require 'demisus/board'

module Demisus
  class SudokuSolver
    # Needs event listeners for removing candidates and for assigning numbers
    # to cells. Some kind of on_candidate_removal and on_number_assignment

    # def self.define_rule  # presumably in different file(s), opening the class

    def initialize(board)
      # board is an array of arrays of numbers (or nil)
    end

    def consistent?
    def solve!
    def unsolved_cells
    def simplify!

    private

    def remove_candidate!(row, col)
    def supercell_for(row, col)
  end
end
