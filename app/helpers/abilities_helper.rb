module AbilitiesHelper
  ##
  # Linearizes the Wilson-score progress used by ability calculations. For example, 0.98 and 0.99 are not far away on a
  # linear scale, but mean a change of about 2x for the actual limit used by the algorithm. This method takes that into
  # account and provides an indicator of progress on a linear scale, for use in progress bars.
  # @param score [Float] The Wilson score result to linearize.
  # @return [Float] The linearized score.
  def linearize_progress(score)
    linear_score = ((4 * score) - 2) / (1 - score)
    [0, linear_score].max.to_f
  end

  ##
  # Provides an error message for when a user is unable to complete an ability-restricted action, either because the
  # user doesn't have the ability or because it has been suspended.
  # @param internal_id [String] The +internal_id+ attribute of the ability in question.
  # @return [String] An error message appropriate to the circumstances.
  def ability_err_msg(internal_id, action = nil)
    ability = Ability.find_by internal_id: internal_id
    ua = current_user&.privilege(ability.internal_id)
    if ua&.suspended?
      if action.nil?
        "Your use of the #{ability.name} ability has been temporarily suspended. " \
          "See /abilities/#{ability.internal_id} for more information."
      else
        "Your use of the #{ability.name} ability has been temporarily suspended, so you cannot #{action}." \
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
