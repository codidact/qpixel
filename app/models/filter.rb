class Filter < ApplicationRecord
  belongs_to :user
  serialize :include_tags, Array
  serialize :exclude_tags, Array

  # Helper method to convert it to the form expected by the client
  def json
    {
      min_score: min_score,
      max_score: max_score,
      min_answers: min_answers,
      max_answers: max_answers,
      include_tags: Tag.where(id: include_tags).map { |tag| [tag.name, tag.id] },
      exclude_tags: Tag.where(id: exclude_tags).map { |tag| [tag.name, tag.id] },
      status: status,
      system: user_id == -1
    }
  end
end
