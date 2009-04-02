require 'test/unit'
require 'demisus/solver'

class TestSudokuSolverSimple < Test::Unit::TestCase
  def test_consistent?
    inconsistent = [[1,  2,  3,  4,  5,  6,  7,  8,  9  ],
                    [2,  3,  4,  5,  6,  1,  8,  9,  7  ],
                    [3,  4,  5,  6,  nil,nil,nil,7,  2  ],
                    [4,  5,  6,  2,  1,  3,  nil,nil,nil],
                    [4,  5,  6,  nil,2,  1,  nil,nil,nil],
                    [4,  5,  6,  nil,1,  2,  nil,nil,nil],
                    [4,  5,  6,  2,  1,  3,  nil,nil,nil],
                    [4,  5,  6,  nil,2,  1,  nil,nil,nil],
                    [4,  5,  6,  nil,1,  2,  nil,nil,nil]]
    solver_inconsistent = Demisus::SudokuSolver.new(inconsistent)
    assert_equal false, solver_inconsistent.consistent?


    consistent = [[nil,nil,9,  nil,nil,7,  5,  2,  nil],
                  [8,  nil,nil,nil,4,  5,  nil,nil,nil],
                  [3,  nil,1,  nil,6,  nil,4,  nil,7  ],
                  [1,  4,  nil,nil,nil,nil,nil,nil,nil],
                  [nil,7,  6,  nil,nil,nil,2,  3,  nil],
                  [nil,nil,nil,nil,nil,nil,nil,9,  4  ],
                  [2,  nil,3,  nil,1,  nil,9,  nil,6  ],
                  [nil,nil,nil,6,  3,  nil,nil,nil,1  ],
                  [nil,1,  4,  7,  nil,nil,3,  nil,nil]]
    solver_consistent = Demisus::SudokuSolver.new(consistent)
    assert solver_consistent.consistent?
  end

  def test_obvious_candidates
    numbers = [[nil,nil,9,  nil,nil,7,  5,  2,  nil],
               [8,  nil,nil,nil,4,  5,  nil,nil,nil],
               [3,  nil,1,  nil,6,  nil,4,  nil,7  ],
               [1,  4,  nil,nil,nil,nil,nil,nil,nil],
               [nil,7,  6,  nil,nil,nil,2,  3,  nil],
               [nil,nil,nil,nil,nil,nil,nil,9,  4  ],
               [2,  nil,3,  nil,1,  nil,9,  nil,6  ],
               [nil,nil,nil,6,  3,  nil,nil,nil,1  ],
               [nil,1,  4,  7,  nil,nil,3,  nil,nil]]
    solver = Demisus::SudokuSolver.new(numbers)
    first_cell   = solver.board.rows[0][0]
    another_cell = solver.board.rows[2][1]
    assert first_cell.candidates.include?(9),
           "Before executing any rules, the obvious candidates should be there"
    assert another_cell.candidates.include?(9),
           "Before executing any rules, the obvious candidates should be there"
    cell_with_9 = solver.board.rows[0][2]
    assert_equal 9, cell_with_9.number
    solver.remove_obvious_candidates(cell_with_9.i, cell_with_9.j,
                                     cell_with_9.number)
    assert !first_cell.candidates.include?(9),
           "Removing obvious candidates from first region should work"
    assert !another_cell.candidates.include?(9),
           "Removing obvious candidates from first region should work"

    # Now, simulate that we solve some cell
    solved_number = 6
    solver.board.rows[1][1].number = solved_number
    assert !first_cell.candidates.include?(solved_number),
           "Solving a cell should remove obvious candidates automatically"
    assert !another_cell.candidates.include?(solved_number),
           "Solving a cell should remove obvious candidates automatically"
  end
end
