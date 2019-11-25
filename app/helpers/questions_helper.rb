# Provides helper methods for use by views under <tt>QuestionsController</tt>.
module QuestionsHelper
  def my_vote(question)
    user_signed_in? ? question.votes.where(user: current_user).first : nil
  end
end
