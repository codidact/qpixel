# Provides helper methods for use by views under <tt>AnswersController</tt>.
module AnswersHelper
  # Given an answer, returns the vote on it that belongs to the current user, or nil if there isn't one. Simply
  # saves having to clutter up the view getting hold of it every time (which is sort of the point of all helpers, I
  # guess).
  def my_vote(answer)
    if user_signed_in?
      return answer.votes.where(user: current_user).first
    end
    return nil
  end
end
