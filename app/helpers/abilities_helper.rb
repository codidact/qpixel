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

  def ability_err_msg(internal_id, action: nil)
    ability = Ability.find_by internal_id: internal_id
    ua = current_user.privilege(ability.internal_id)
    if ua.suspended?
      if action.nil?
        "Your use of the #{ability.name} ability has been temporarily suspended. " \
        "See /abilities/#{ability.internal_id} for more information."
      else
        "Your use of the #{ability.name} ability has been temporarily suspended. So you cannot #{action}." \
        "See /abilities/#{ability.internal_id} for more information."
      end
    else
      if action.nil?
        "You need the #{ability.name} ability to do this." \
        "See /abilities/#{ability.internal_id} for more information."
      else
        "You need the #{ability.name} ability to #{action}." \
        "See /abilities/#{ability.internal_id} for more information."
      end
    end
  end
end
