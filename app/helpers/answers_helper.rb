# Provides helper methods for use by views under <tt>AnswersController</tt>.
module AnswersHelper
  ##
  # Returns the current user's vote for the specified post, or nil if no user is signed in.
  # @param answer [Post] The post for which to find a vote.
  # @return [Vote, nil]
  def my_vote(answer)
    user_signed_in? ? answer.votes.where(user: current_user).first : nil
  end
end
