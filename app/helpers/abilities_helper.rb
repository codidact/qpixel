module AbilitiesHelper
  # This is a helper that will linearize the Wilson-score
  # progress used by the ability calculations.
  #
  # Problem: 0.98 and 0.99 are not far away on a linear
  # scale, but mean a change of about 2x for the "actual
  # limit" used by the algorithm.
  #
  # Solution: We transform the ideal case formula y=(x+1)/(x+2)
  # to x=(2y-1)/(1-y) and use that for the progress bar.
  def linearize_progress(score)
    linear_score = (2 * score - 1) / (1 - score)
    [0, linear_score].max
  end
end
