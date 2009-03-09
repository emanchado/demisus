module Demisus
  class InvalidCandidateError < ArgumentError; end
  class UnknownEventError < ArgumentError; end
  class InconsistentSudokuError < ArgumentError; end

  class SudokuBoard
    EVENTS = [:set_number, :remove_candidate]

    # Array of SudokuCell
    attr_reader :cells
    # Array (pair of integers)
    attr_reader :region_size
    # Number of elements per row/column
    attr_reader :side_size

    # Builds a new Sudoku board from an Integer matrix (unknown numbers should
    # be nil) and options. The only valid option is "region_size", an Integer
    # Array (pair) with the size of the regions (rows x columns)
    def initialize(board, user_opts={})
      opts = {:region_size => [3,3]}.merge(user_opts)
      @cells       = []
      @region_size = opts[:region_size]
      @side_size   = @region_size[0] * @region_size[1]
      # List of listeners per every event
      @listeners   = {}
      EVENTS.each {|e| @listeners[e] = []}

      if board.size != @side_size
        raise InconsistentSudokuError,
          "Expected #{@side_size} rows, were #{board.size}"
      end
      board.each_with_index do |row, i|
        if row.size != @side_size
          raise InconsistentSudokuError,
            "Expected #{@side_size} columns for row #{i+1}, were #{row.size}"
        end
        j = -1
        @cells.push(row.map {|cell| j += 1; SudokuCell.new(self, i, j, cell)})
      end
    end

    # Returns a Range with the possible candidates for the cells inside the
    # board
    def possible_candidates
      @possible_candidates ||= (1..@side_size)
    end

    # Returns the list of unsolved cells
    def unsolved_cells
      @cells.flatten.find_all {|c| not c.solved? }
    end

    # Returns the list of cells comprising the region containing the given
    # coordinates
    def region_for(i, j)
      raise NotImplementedError
    end

    # Defines a new listener for the given event. When the event occurs, the
    # given block will be called with appropriate parameters
    def define_listener(event, &blk)
      event_sym = event.to_sym
      if EVENTS.include? event_sym
        @listeners[event_sym] << blk
      else
        raise UnknownEventError, "Unknown event #{event}"
      end
    end

    # Sets the number in the given position
    def set_number(i, j, number)
      @cells[i][j].number = number
      call_listeners(:set_number, [i, j, number])
    end

    # Removes a candidate from the given position
    def remove_candidate(i, j, candidate)
      @cells[i][j].remove_candidate(candidate)
      call_listeners(:remove_candidate, [i, j, candidate])
    end


    private

    # Call the defined listeners for the given event, passing the given list of
    # params
    def call_listeners(event, params)
      @listeners[event.to_sym].each do |blk|
        blk.call(*params)
      end
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
        raise InvalidCandidateError,
          "Invalid candidate #{number}, possible are: #{candidates.to_a.join(", ")}"
      end
      @number     = number
      @candidates = [number]
      if number.nil?
        @candidates = candidates.reject {|c| c == number}
      end
    end

    def solved?
      @number != nil
    end

    def number=(new_number)
      @number = new_number
      if new_number
        @candidates = [@number]
      end
    end

    def remove_candidate(candidate)
      if @candidates.include candidate
        @candidates.reject! candidate

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
