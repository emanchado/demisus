module Demisus
  class InvalidCandidate < ArgumentError; end

  class SudokuBoard
    # Array of SudokuCell
    attr_reader :cells
    # Array (pair of integers)
    attr_reader :region_size

    # Builds a new Sudoku board from an Integer matrix (unknown numbers should
    # be nil) and options. The only valid option is "region_size", an Integer
    # Array (pair) with the size of the regions (rows x columns)
    def initialize(board, user_opts={})
      opts = {:region_size => [3,3]}.merge(user_opts)
      @cells       = []
      @region_size = opts[:region_size]
      @side_size   = @region_size[0] * @region_size[1]
      if board.size != @side_size
        raise ArgumentError, "Expected #{@side_size} rows, were #{board.size}"
      end
      board.each_with_index do |row, i|
        if row.size != @side_size
          raise ArgumentError,
            "Expected #{@side_size} columns for row #{i+1}, were #{row.size}"
        end
        j = -1
        @cells.push(row.map {|cell| j += 1; SudokuCell.new(self, i, j, cell)})
      end
    end

    # Returns a Range with the possible candidates for the cells inside the
    # board
    def possible_candidates
      @possible_candidates ||= (1..(@region_size[0] * @region_size[1]))
    end
  end


  class SudokuCell
    attr_reader :board
    attr_reader :coords
    attr_reader :number
    attr_reader :candidates

    # Builds a new Sudoku cell for the given board from the coordinates and a
    # number (or nil, if the cell number is not known yet)
    def initialize(board, i, j, number=nil)
      @board      = board
      @coords     = [i, j]
      candidates = board.possible_candidates
      if not number.nil? and not candidates.include? number
        raise InvalidCandidate,
          "Invalid candidate #{number}, possible are: #{candidates.to_a.join(", ")}"
      end
      @number     = number
      @candidates = candidates.reject {|c| c == number}
    end
  end
end
