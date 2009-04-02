require 'test/unit'
require 'demisus/board'
require 'demisus/solver'
require 'flexmock/test_unit'

class TestSudokuSolverRules < Test::Unit::TestCase
  def execute_rule(id, *params)
    Demisus::SudokuSolver.rule_by_id(id)[:action].call(*params)
  end

  def test_naked_pairs
    board_mock = flexmock("board")
    board_mock.should_receive(:call_listeners).times(2).and_return(nil)
    board_mock.should_receive(:possible_candidates).times(3).and_return(1..2)
    cells = [Demisus::SudokuCell.new(board_mock, 0, 0, nil),
             Demisus::SudokuCell.new(board_mock, 0, 1, nil),
             Demisus::SudokuCell.new(board_mock, 0, 2, nil)]
    # Artificially set the candidates for two of the cells
    cells[0].instance_variable_set("@candidates", [1,2])
    cells[1].instance_variable_set("@candidates", [2,5])
    cells[2].instance_variable_set("@candidates", [2,1])

    execute_rule(:naked_pairs, cells)

    assert !cells[1].candidates.include?(2),
           "The second cell shouldn't have '2' as candidate"
    assert_equal 5, cells[1].number,
                 "The second cell should be solved with '5'"
  end

  def test_single_place_candidate
    board_mock = flexmock("board")
    board_mock.should_receive(:call_listeners).times(1).and_return(nil)
    board_mock.should_receive(:possible_candidates).times(4).and_return(1..7)
    cells = [Demisus::SudokuCell.new(board_mock, 0, 0, nil),
             Demisus::SudokuCell.new(board_mock, 0, 1, nil),
             Demisus::SudokuCell.new(board_mock, 0, 2, nil),
             Demisus::SudokuCell.new(board_mock, 0, 3, 7)]
    # Artificially set the candidates for two of the cells
    cells[0].instance_variable_set("@candidates", [1,2])
    cells[1].instance_variable_set("@candidates", [2,5,3])
    cells[2].instance_variable_set("@candidates", [3,1,7])

    execute_rule(:single_place_candidate, cells)

    assert !cells[1].candidates.include?(2),
           "The second cell shouldn't have '2' as candidate"
    assert !cells[1].candidates.include?(3),
           "The second cell shouldn't have '2' as candidate"
    assert_equal 5, cells[1].number,
           "The second cell should be solved with '5'"
    assert !cells[0].solved?,
           "The first cell shouldn't be solved"
    assert cells[2].candidates.include?(7),
           "The third cell should keep '7' as candidate with this rule"
    assert !cells[2].solved?,
           "The third cell shouldn't be solved"
    assert cells[3].solved?,
           "The fourth cell should stay solved"
  end

  def test_candidate_in_single_row_or_column
    require 'demisus/importers'
    numbers = Demisus::Importers::from_simple_string(<<EOS)
______
______
______
______
2_1___
4_____
EOS
    board = Demisus::SudokuBoard.new(numbers, :region_size => [2, 3])

    # Candidates for the bottom-left region
    board.rows[4][1].instance_variable_set("@candidates", [5,3])
    board.rows[5][1].instance_variable_set("@candidates", [5,6])
    board.rows[5][2].instance_variable_set("@candidates", [3,6])
    # Candidates for the 2nd column
    board.rows[0][1].instance_variable_set("@candidates", [3,1])
    board.rows[1][1].instance_variable_set("@candidates", [1,3,2])
    board.rows[2][1].instance_variable_set("@candidates", [3,5])
    board.rows[3][1].instance_variable_set("@candidates", [5,6,1])
    # Candidates for the 6th row
    board.rows[5][3].instance_variable_set("@candidates", [3,6,1])
    board.rows[5][4].instance_variable_set("@candidates", [1,3])
    board.rows[5][5].instance_variable_set("@candidates", [6,5])

    # Execute the rule
    execute_rule(:candidate_in_single_row_or_column,
                 board.region_for(5,0),
                 board)

    # Check that the right candidates have been removed
    # 1) 5 from 2nd column
    assert !board.rows[0][1].candidates.include?(5)
    assert !board.rows[1][1].candidates.include?(5)
    assert !board.rows[2][1].candidates.include?(5)
    assert !board.rows[3][1].candidates.include?(5)
    # 2) 6 from 6th row
    assert !board.rows[5][3].candidates.include?(6)
    assert !board.rows[5][4].candidates.include?(6)
    assert !board.rows[5][5].candidates.include?(6)

    # Check that final numbers are correct
    # 1) after removing 5 from 2nd column
    assert board.rows[2][1].solved?
    assert_equal 3, board.rows[2][1].number
    # 2) after removing 6 from 6th row
    assert board.rows[5][5].solved?
    assert_equal 5, board.rows[5][5].number

    # Check that the candidates haven't been removed from the region itself
    # 1) 5 from 2nd column
    assert(board.rows[4][1].candidates.include? 5)
    assert(board.rows[5][1].candidates.include? 5)
    # 2) 6 from 6th row
    assert(board.rows[5][1].candidates.include? 6)
    assert(board.rows[5][2].candidates.include? 6)
  end
end
