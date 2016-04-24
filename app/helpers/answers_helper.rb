module AnswersHelper
  def my_vote(answer)
    if user_signed_in?
      return answer.votes.where(:user => current_user).first
    end
    return nil
  end
end
