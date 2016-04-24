module AnswersHelper
  # Returns the entire vote object. Vote type 0 is up, 1 is down.
  def my_vote(answer)
    if user_signed_in?
      return answer.votes.where(:user => current_user).first
    end
    return nil
  end
end
