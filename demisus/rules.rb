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
