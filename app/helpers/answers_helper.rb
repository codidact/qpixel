# Provides helper methods for use by views under <tt>AnswersController</tt>.
module AnswersHelper
  def my_vote(answer)
    user_signed_in? ? answer.votes.where(user: current_user).first : nil
  end
end
