# Provides helper methods for use by views under <tt>QuestionsController</tt>.
module QuestionsHelper
  # Essentially identical to <tt>AnswersHelper#my_vote</tt> - returns the current user's vote on the given question,
  # or <tt>nil</tt> if there isn't one.
  def my_vote(question)
    user_signed_in? ? question.votes.where(user: current_user).first : nil
  end
end
