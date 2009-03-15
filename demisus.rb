require 'demisus/solver'
require 'demisus/view/html_exporter'

numbers_consistent = [[nil,nil,9,  nil,nil,7,  5,  2,  nil],
                      [8,  nil,nil,nil,4,  5,  nil,nil,nil],
                      [3,  nil,1,  nil,6,  nil,4,  nil,7  ],
                      [1,  4,  nil,nil,nil,nil,nil,nil,nil],
                      [nil,7,  6,  nil,nil,nil,2,  3,  nil],
                      [nil,nil,nil,nil,nil,nil,nil,9,  4  ],
                      [2,  nil,3,  nil,1,  nil,9,  nil,6  ],
                      [nil,nil,nil,6,  3,  nil,nil,nil,1  ],
                      [nil,1,  4,  7,  nil,nil,3,  nil,nil]]
solver = Demisus::SudokuSolver.new(numbers_consistent)
puts "Consistent? #{solver.consistent?}"
puts "Unsolved cells: #{solver.number_unsolved_cells}"


exporter = Demisus::HtmlExporter.new(solver.board)

solver.simplify!
