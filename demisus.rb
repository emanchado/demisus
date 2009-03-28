require 'demisus/solver'
require 'demisus/view/html_exporter'
require 'demisus/importers'

def die_in_error(extra_msg=nil)
  $stderr.puts "ERROR: #{extra_msg}" if extra_msg
  $stderr.puts "Syntax: #{$0} <path/to/sudoku/file>"
  exit 1
end

sudoku_path = ARGV.first

if sudoku_path.nil?
  die_in_error "You haven't specified any parameter!"
end
if not File.readable? sudoku_path
  die_in_error "Can't read file #{sudoku_path}"
end
puts "Solving #{sudoku_path}"
numbers_consistent = Demisus::Importers.from_simple_file(sudoku_path)
solver = Demisus::SudokuSolver.new(numbers_consistent)
puts "Initially consistent? #{solver.consistent?}"
puts "Number of unsolved cells: #{solver.number_unsolved_cells}"


exporter = Demisus::View::HtmlExporter.new(solver.board)

solver.solve!
solver.ensure_consistency!
