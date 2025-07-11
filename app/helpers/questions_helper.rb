# Provides helper methods for use by views under <tt>QuestionsController</tt>.
module QuestionsHelper
  ##
  # Returns the current user's vote for the specified post, or nil if no user is signed in.
  # @param question [Post] The post for which to find a vote.
  # @return [Vote, nil]
  def my_vote(question)
    user_signed_in? ? question.votes.where(user: current_user).first : nil
  end
end
