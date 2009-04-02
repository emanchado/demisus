module Demisus
  module Importers
    def from_simple_file(path)
      return from_simple_string(File.read(path))
    end

    def from_simple_string(string)
      numbers = []
      string.each_line do |line|
        row = []
        line.chomp.each_char do |c|
          row << (c == '_' ? nil : c.to_i)
        end
        numbers << row
      end
      return numbers
    end

    module_function :from_simple_file
    module_function :from_simple_string
  end
end
