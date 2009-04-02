require 'demisus/mixins/listeners'

module Demisus
  class InvalidCandidateError < ArgumentError; end
  class UnknownEventError < ArgumentError; end
  class InconsistentSudokuError < ArgumentError; end
  class InvalidSudokuError < ArgumentError; end

  class SudokuBoard
    include Demisus::Mixins::Listeners

    def event_types; [:set_number, :remove_candidate]; end

    # Array of SudokuCell
    attr_reader :rows
    attr_reader :columns
    # Array (pair of integers)
    attr_reader :region_size
    # Number of elements per row/column
    attr_reader :side_size

    # Builds a new Sudoku board from an Integer matrix (unknown numbers should
    # be nil) and options. The only valid option is "region_size", an Integer
    # Array (pair) with the size of the regions (rows x columns)
    def initialize(board, user_opts={})
      opts = {:region_size => [3,3]}.merge(user_opts)
      @rows        = []
      @columns     = []
      @region_size = opts[:region_size]
      @side_size   = @region_size[0] * @region_size[1]
      initialize_listeners

      if board.size != @side_size
        raise InvalidSudokuError,
          "Expected #{@side_size} rows, were #{board.size}"
      end
      board.each_with_index do |row, i|
        if row.size != @side_size
          raise InvalidSudokuError,
            "Expected #{@side_size} columns for row #{i+1}, were #{row.size}"
        end
        j = 0
        @rows[i] = []
        current_row = @rows[i]
        row.each do |n|
          cell = SudokuCell.new(self, i, j, n)
          current_row.push(cell)
          @columns[j]    ||= []
          @columns[j][i]   = cell
          j += 1
        end
      end
    end

    def each_row(&blk)
      @rows.each &blk
    end

    def each_column(&blk)
      @columns.each &blk
    end

    def each_region(&blk)
      0.step(@side_size-1, @region_size[0]) do |i|
        0.step(@side_size-1, @region_size[1]) do |j|
          blk.call(@rows[i ... i+@region_size[0]].map {|row|
            row[j ... j+@region_size[1]]
          }.flatten)
        end
      end
    end

    # Returns a Range with the possible candidates for the cells inside the
    # board
    def possible_candidates
      @possible_candidates ||= (1..@side_size)
    end

    # Returns the list of unsolved cells
    def unsolved_cells
      @rows.flatten.find_all {|c| not c.solved? }
    end

    # Returns the list of cells comprising the region containing the given
    # coordinates
    def region_for(i, j)
      region_i = (i / @region_size[0]) * @region_size[0]
      region_j = (j / @region_size[1]) * @region_size[1]
      @rows[region_i ... region_i+@region_size[0]].map {|row|
            row[region_j ... region_j+@region_size[1]]
          }.flatten
    end
  end




  class SudokuCell
    attr_reader :board
    attr_reader :i, :j
    attr_reader :number
    attr_reader :candidates

    # Builds a new Sudoku cell for the given board from the coordinates and a
    # number (or nil, if the cell number is not known yet)
    def initialize(board, i, j, number=nil)
      @board      = board
      @i          = i
      @j          = j
      candidates = board.possible_candidates
      if not number.nil? and not candidates.include? number
        raise InvalidCandidateError,
          "Invalid candidate #{number}, possible are: #{candidates.to_a.join(", ")}"
      end
      @number     = number
      if number
        @candidates = [number]
      else
        @candidates = candidates.to_a
      end
    end

    def solved?
      @number != nil
    end

    def number=(new_number)
      @number = new_number
      if new_number
        @candidates = [@number]
        @board.call_listeners(:set_number, [@i, @j, new_number])
      end
    end

    def remove_candidate(candidate)
      if @candidates.include? candidate
        @board.call_listeners(:remove_candidate, [@i, @j, candidate])
        @candidates.reject! {|c| c == candidate}

        case @candidates.length 
        when 0
          raise InconsistentSudoku,
            "I'm left with 0 candidates for cell #{i},#{j}"
        when 1
          self.number = @candidates.first
        end
      else
        raise InvalidCandidateError,
              "Can't remove candidate #{candidate} from cell #{i},#{j}. " +
                "No such candidate"
      end
    end
  end
end
