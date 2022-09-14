class Filter < ApplicationRecord
  belongs_to :user, required: true, class_name: 'User'

  # Helper method to convert it to the form expected by the client
  def json
    {
      'score-min' => min_score,
      'score-max' => max_score,
      'answers-min' => min_answers,
      'answers-max' => max_answers,
      'status' => status,
      'system' => user_id == -1
    }
  end
end
