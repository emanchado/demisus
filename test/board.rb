require 'test/unit'
require 'demisus/board'

class TestSudokuBoard < Test::Unit::TestCase
  def test_region_size
    numbers32 = [[1,  2,  3,  4,  5,  6  ],
                 [nil,3,  4,  5,  6,  1  ],
                 [3,  4,  5,  6,  nil,nil],
                 [4,  nil,nil,2,  1,  3  ],
                 [nil,nil,6,  nil,2,  nil],
                 [nil,5,  nil,nil,nil,2  ]]

    numbers33 = [[1,  2,  3,  4,  5,  6,  7,  8,  9  ],
                 [2,  3,  4,  5,  6,  1,  8,  9,  7  ],
                 [3,  4,  5,  6,  nil,nil,nil,7,  2  ],
                 [4,  5,  6,  2,  1,  3,  nil,nil,nil],
                 [4,  5,  6,  nil,2,  1,  nil,nil,nil],
                 [4,  5,  6,  nil,1,  2,  nil,nil,nil],
                 [4,  5,  6,  2,  1,  3,  nil,nil,nil],
                 [4,  5,  6,  nil,2,  1,  nil,nil,nil],
                 [4,  5,  6,  nil,1,  2,  nil,nil,nil]]
    b32 = Demisus::SudokuBoard.new(numbers32,
                                   :region_size => [3,2])
    assert_equal [3,2], b32.region_size

    assert_raises Demisus::InvalidSudokuError do
      Demisus::SudokuBoard.new(numbers32)
    end

    b33_implicit = Demisus::SudokuBoard.new(numbers33)
    assert_equal [3,3], b33_implicit.region_size

    b33 = Demisus::SudokuBoard.new(numbers33,
                                   :region_size => [3,3])
    assert_equal [3,3], b33.region_size

    assert_raises Demisus::InvalidSudokuError do
      Demisus::SudokuBoard.new(numbers33,
                               :region_size => [3,2])
    end
  end

  def test_invalid_candidates
    numbers = [[1,  2,  3,  4,  5,  6  ],
               [2,  3,  4,  5,  6,  1  ],
               [3,  4,  5,  6,  nil,nil],
               [4,  5,  6,  2,  1,  3  ],
               [4,  5,  6,  nil,2,  1  ],
               [4,  5,  6,  nil,1,  2  ]]
    numbers_invalid = [[1,  2,  3,  4,  5,  6  ],
                       [2,  3,  4,  5,  6,  1  ],
                       [3,  4,  5,  7,  nil,nil],   # 7 doesn't make sense!
                       [4,  5,  6,  2,  1,  3  ],
                       [4,  5,  6,  nil,2,  1  ],
                       [4,  5,  6,  nil,1,  2  ]]
    numbers_invalid2 = [[1,  2,  3,  4,  5,  6  ],
                        [2,  3,  4,  5,  6,  1  ],
                        [3,  4,  5,  0,  nil,nil],   # 0 doesn't make sense!
                        [4,  5,  6,  2,  1,  3  ],
                        [4,  5,  6,  nil,2,  1  ],
                        [4,  5,  6,  nil,1,  2  ]]
    assert_nothing_raised Demisus::InvalidCandidateError do
      Demisus::SudokuBoard.new(numbers, :region_size => [3,2])
    end
    assert_raises Demisus::InvalidCandidateError do
      Demisus::SudokuBoard.new(numbers_invalid, :region_size => [3,2])
    end
    assert_raises Demisus::InvalidCandidateError do
      Demisus::SudokuBoard.new(numbers_invalid2, :region_size => [3,2])
    end
  end

  def test_each_column
    numbers = [[1,  2,  3,  4,  5,  6  ],
               [2,  3,  4,  5,  6,  1  ],
               [3,  4,  5,  6,  nil,nil],
               [4,  5,  6,  2,  1,  3  ],
               [4,  5,  6,  nil,2,  1  ],
               [4,  5,  6,  nil,1,  2  ]]
    board = Demisus::SudokuBoard.new(numbers, :region_size => [3,2])
    number_in_column = {0 => [], 1 => [], 2 => [],
                        3 => [], 4 => [], 5 => []}
    column_counter = 0
    board.each_column do |col|
      col.each do |cell|
        number_in_column[column_counter] << cell.number
      end
      column_counter += 1
    end

    assert_equal [1, 2, 3,   4, 4,   4],   number_in_column[0]
    assert_equal [2, 3, 4,   5, 5,   5],   number_in_column[1]
    assert_equal [3, 4, 5,   6, 6,   6],   number_in_column[2]
    assert_equal [4, 5, 6,   2, nil, nil], number_in_column[3]
    assert_equal [5, 6, nil, 1, 2,   1],   number_in_column[4]
    assert_equal [6, 1, nil, 3, 1,   2],   number_in_column[5]
  end

  def test_each_region
    numbers = [[1,  2,  3,  4,  5,  6  ],
               [2,  3,  4,  5,  6,  1  ],
               [3,  4,  5,  6,  nil,nil],
               [4,  5,  6,  2,  1,  3  ],
               [4,  5,  6,  nil,2,  1  ],
               [4,  5,  6,  nil,1,  2  ]]
    board = Demisus::SudokuBoard.new(numbers, :region_size => [2,3])
    actual_regions = []
    board.each_region do |region|
      actual_regions << region.map {|c| c.number}
    end
    assert_equal [1,   2,   3,   2,   3,   4], actual_regions[0]
    assert_equal [4,   5,   6,   5,   6,   1], actual_regions[1]
    assert_equal [3,   4,   5,   4,   5,   6], actual_regions[2]
    assert_equal [6,   nil, nil, 2,   1,   3], actual_regions[3]
    assert_equal [4,   5,   6,   4,   5,   6], actual_regions[4]
    assert_equal [nil, 2,   1,   nil, 1,   2], actual_regions[5]
  end
end
