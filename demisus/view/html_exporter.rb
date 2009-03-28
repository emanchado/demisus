require 'erb'
require 'demisus/solver'

module Demisus::View
  class HtmlExporter
    def initialize(board)
      @board = board
      @step  = 0

      @board.define_listener(:set_number) do |i,j,n|
        changed_board(i, j, :action => :set_number,
                            :number => n)
      end
      @board.define_listener(:remove_candidate) do |i,j,n|
        changed_board(i, j, :action => :remove_candidate,
                            :number => n)
      end
    end

    def board_html
      ERB.new(<<-'EOHTMLT'.gsub(/^\s+/, ""), nil, '-').result binding
<div class="sudoku-board">
  <%- @board.each_row do |row| -%>
<div class="sudoku-row">
      <%- row.each do |cell| -%>
<div class="sudoku-cell">
          <% if cell.number %>
            <span class="sudoku-number"><%= cell.number %></span>
          <% else %>
            <% cell.candidates.each_with_index do |candidate, i| %>
              <span
                class="sudoku-candidate sudoku-candidate-<%= i
                %>"><%= candidate %></span>
            <% end %>
          <% end %>
</div><%- end -%>
</div>
  <%- end -%>
</div>
EOHTMLT
    end

    def board_css_defs
      ERB.new(<<-'EOHTMLT'.gsub(/^\s+/, ""), nil, '-').result binding
        .sudoku-board {
          border-collapse: collapse;
        }
        .sudoku-row:first-child .sudoku-cell {
          border-top: 1px solid;
        }
        .sudoku-row {
          padding: 0;
          margin: 0;
        }
        .sudoku-cell:first-child {
          border-left: 1px solid;
        }
        <% @board.region_size[0].step(@board.side_size-1, @board.region_size[0]) do |n| %>
          .sudoku-row:nth-child(<%= n %>) .sudoku-cell {
            border-bottom: 3px solid;
          }
        <% end %>
        <% @board.region_size[1].step(@board.side_size-1, @board.region_size[1]) do |n| %>
          .sudoku-cell:nth-child(<%= n %>) {
            border-right: 3px solid;
          }
        <% end %>
        .sudoku-cell {
          height: 50px;
          width: 50px;
          border-bottom: 1px solid;
          border-right: 1px solid;
          margin: 0;
          vertical-align: middle;
          text-align: center;
          position: relative;
          display: inline-block;
        }
        .sudoku-number {
          font-size: 24pt;
          color: #00f;
          line-height: 50px;
        }
        .sudoku-candidate {
          font-size: 10pt;
          color: #888;
          margin: 1px;
        }

        .sudoku-candidate-0 {
          position: absolute;
          left: 0;
          top: 0;
        }
        .sudoku-candidate-1 {
          position: absolute;
          width: 50px;
          text-align: center;
          top: 0;
        }
        .sudoku-candidate-2 {
          position: absolute;
          right: 0%;
          top: 0;
        }
        .sudoku-candidate-3 {
          position: absolute;
          left: 0;
          line-height: 50px;
        }
        .sudoku-candidate-4 {
          position: absolute;
          width: 50px;
          text-align: center;
          line-height: 50px;
        }
        .sudoku-candidate-5 {
          position: absolute;
          right: 0%;
          line-height: 50px;
        }
        .sudoku-candidate-6 {
          position: absolute;
          left: 0;
          bottom: 0%;
        }
        .sudoku-candidate-7 {
          position: absolute;
          width: 50px;
          text-align: center;
          bottom: 0%;
        }
        .sudoku-candidate-8 {
          position: absolute;
          right: 0%;
          bottom: 0%;
        }
EOHTMLT
    end

    def to_html(user_opts={})
      opts = {:extra_css  => "",
              :extra_html => ""}.merge(user_opts)
      ERB.new(<<-'EOHTMLT'.gsub(/^\s+/, ""), nil, '-').result binding
        <!DOCTYPE html>
        <html>
          <head>
            <title>Demisus' Sudoku HTML exporter</title>
            <style>
              <%= board_css_defs %>
              <%= opts[:extra_css] %>
            </style>
          </head>
          <body>
            <%= board_html %>
            <%= opts[:extra_html] %>
          </body>
        </html>
EOHTMLT
    end

    def changed_board(i, j, user_opts={})
      opts = {}.merge(user_opts)
      filename = "sudoku-steps/#{sprintf("%03i", @step)}.html"
      explanation = case opts[:action]
                    when :remove_candidate
                      "Remove candidate #{opts[:number]} from #{i+1},#{j+1}"
                    when :set_number
                      "Set number #{opts[:number]} in #{i+1},#{j+1}"
                    end
      File.open(filename, "w") do |f|
        f.print to_html(:extra_css => <<EOCSS, :extra_html => <<EOHTML)
          .sudoku-row:nth-child(#{i+1}) .sudoku-cell:nth-child(#{j+1}) {
            background-color: #ff8;
          }
EOCSS
        <em>#{explanation}</em>
        <a href="#{sprintf("%03i", @step+1)}.html">Next step</a>
EOHTML
      end
      @step += 1
    end
  end
end
