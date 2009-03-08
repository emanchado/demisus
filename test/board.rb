require 'test/unit'
require 'demisus/board'

class TestSudokuBoard < Test::Unit::TestCase
  def test_region_size
    numbers32 = [[1,  2,  3,  4,  5,  6  ],
                 [2,  3,  4,  5,  6,  1  ],
                 [3,  4,  5,  6,  nil,nil],
                 [4,  5,  6,  2,  1,  3  ],
                 [4,  5,  6,  nil,2,  1  ],
                 [4,  5,  6,  nil,1,  2  ]]
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

    assert_raises ArgumentError do
      Demisus::SudokuBoard.new(numbers32)
    end

    b33_implicit = Demisus::SudokuBoard.new(numbers33)
    assert_equal [3,3], b33_implicit.region_size

    b33 = Demisus::SudokuBoard.new(numbers33,
                                   :region_size => [3,3])
    assert_equal [3,3], b33.region_size

    assert_raises ArgumentError do
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
    assert_nothing_raised Demisus::InvalidCandidate do
      Demisus::SudokuBoard.new(numbers, :region_size => [3,2])
    end
    assert_raises Demisus::InvalidCandidate do
      Demisus::SudokuBoard.new(numbers_invalid, :region_size => [3,2])
    end
    assert_raises Demisus::InvalidCandidate do
      Demisus::SudokuBoard.new(numbers_invalid2, :region_size => [3,2])
    end
  end
end
