module Demisus
  module Importers
    def from_simple_file(path)
      numbers = []
      File.readlines(path).each do |line|
        row = []
        line.chomp.each_char do |c|
          row << (c == '_' ? nil : c.to_i)
        end
        numbers << row
      end
      return numbers
    end

    module_function :from_simple_file
  end
end
