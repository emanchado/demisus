require 'test/unit'
require 'demisus/board'
require 'demisus/solver'
require 'flexmock/test_unit'

class TestSudokuSolverRules < Test::Unit::TestCase
  def execute_rule(id, cells)
    Demisus::SudokuSolver.rule_by_id(id)[:action].call(cells)
  end

  def test_final_numbers
    board_mock = flexmock("board")
    board_mock.should_receive(:call_listeners).times(2).and_return(nil, nil)
    board_mock.should_receive(:possible_candidates).times(2).and_return(1..2)
    cells = [Demisus::SudokuCell.new(board_mock, 0, 0, 1),
             Demisus::SudokuCell.new(board_mock, 0, 1, nil)]
    assert cells[1].candidates.include?(1),
           "Second cell should have '1' as candidate before any rules"

    execute_rule(:final_numbers, cells)

    assert !cells[1].candidates.include?(1),
           "Second cell shouldn't have '1' as candidate after rules"
    assert cells[1].candidates.include?(2),
           "Second cell should have '2' as candidate after rules"
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
    cells[2].instance_variable_set("@candidates", [1,2])

    execute_rule(:naked_pairs, cells)

    assert !cells[1].candidates.include?(2),
           "The second cell shouldn't have '2' as candidate"
    assert_equal 5, cells[1].number
  end
end
