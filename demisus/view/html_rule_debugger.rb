require 'erb'
require 'demisus/solver'
require 'demisus/view/html_exporter'

module Demisus::View
  class HtmlRuleDebugger < HtmlExporter
    def initialize(solver, rule_to_debug)
      @solver = solver
      @board = solver.board
      @step  = 0
      @executing_rule = false

      @solver.define_listener(:before_applying_rule) do |rule|
        if rule[:id] == rule_to_debug
          $stderr.puts "Running rule #{rule_to_debug}"
          @executing_rule = true
        end
      end
      @solver.define_listener(:after_applying_rule) do |rule|
        @executing_rule = false
      end
      @board.define_listener(:set_number) do |i,j,n|
        if @executing_rule
          changed_board(i, j, :action => :set_number,
                              :number => n)
        end
      end
      @board.define_listener(:remove_candidate) do |i,j,n|
        if @executing_rule
          changed_board(i, j, :action => :remove_candidate,
                              :number => n)
        end
      end
    end
  end
end
