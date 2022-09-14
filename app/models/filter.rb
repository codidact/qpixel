class Filter < ApplicationRecord
  belongs_to :user

  # Helper method to convert it to the form expected by the client
  def json
    {
      min_score: min_score,
      max_score: max_score,
      min_answers: min_answers,
      max_answers: max_answers,
      status: status,
      system: user_id == -1
    }
  end
end
