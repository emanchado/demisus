require 'demisus/solver'

ss = Demisus::SudokuSolver

ss.define_rule(:cell_group,
               :naked_pairs,
               "Pair of cells with same candidates discard those for the rest",
               "A pair of cells having the same pair of candidates as only
               possibilities discard those candidates from the rest of the
               row/column/region") do |cells|
  unsolved = cells.find_all {|c| not c.solved?}
  # First, look for a pair of cells having the same pair of candidates
  candidate_groups_found = {}
  unsolved.each do |cell|
    cands = cell.candidates
    if cands.size == 2
      key = cands.sort.join("|")
      candidate_groups_found[key] ||= []
      candidate_groups_found[key] << cell
    end
  end
  # Now, if found, drop candidates from the rest of the cells
  candidate_groups_found.each_pair do |serial_cands,found_cells|
    raise InconsistentSudokuError if found_cells.size > 2
    next                          if found_cells.size < 2
    cells.each do |cell|
      next if found_cells.include? cell
      cands_to_remove = serial_cands.split("|").map {|i| i.to_i}
      (cands_to_remove & cell.candidates).each do |cand|
        cell.remove_candidate(cand)
      end
    end
  end
end

ss.define_rule(:cell_group,
               :single_place_candidate,
               "A candidate is the solution for the only cell having it",
               "A candidate that appears in a single cell inside a group must
               be the solution for that cell") do |cells|
  # Collect, for each possible candidate, which cells consider it. Also
  # count the final numbers, to avoid assigning already existing final
  # numbers
  cells_for_candidate = {}
  cells.each do |cell|
    cell.candidates.each do |cand|
      cells_for_candidate[cand] ||= []
      cells_for_candidate[cand] << cell
    end
  end
  # Now, if some candidate has a single cell, set that candidate as
  # solution for the cell
  cells_for_candidate.each_pair do |cand, cells|
    if cells.size == 1 and not cells.first.solved?
      cells.first.number = cand
    end
  end
end

ss.define_rule(:region,
               :candidate_in_single_row_or_column,
               "Candidate in single row/column in region discards from rest",
               "A candidate occurring in a single row/column inside a region
               discards that candidate from the whole row/column") do |cells, board|
  unsolved = cells.find_all {|c| not c.solved?}
  # Collect, for each possible candidate, which rows/columns consider it
  rows_for_candidate = {}
  cols_for_candidate = {}
  unsolved.each do |cell|
    cell.candidates.each do |cand|
      rows_for_candidate[cand] ||= Set.new
      rows_for_candidate[cand] << cell.i
      cols_for_candidate[cand] ||= Set.new
      cols_for_candidate[cand] << cell.j
    end
  end
  # Now, if some candidate has a single row or column, dicard that candidate
  # from the whole row/column outside that region
  rows_for_candidate.each_pair do |cand, rows_with_cand|
    if rows_with_cand.size == 1
      board.rows[rows_with_cand.first].each do |cell|
        if cell.candidates.include? cand and not cells.include? cell
          cell.remove_candidate cand
        end
      end
    end
  end
  cols_for_candidate.each_pair do |cand, cols_with_cand|
    if cols_with_cand.size == 1
      board.columns[cols_with_cand.first].each do |cell|
        if cell.candidates.include? cand and not cells.include? cell
          cell.remove_candidate cand
        end
      end
    end
  end
end
