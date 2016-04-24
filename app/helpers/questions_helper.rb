module QuestionsHelper
  def my_vote(question)
    if user_signed_in?
      return question.votes.where(:user => current_user).first
    end
    return nil
  end
end
