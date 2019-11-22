class Question < Post
  default_scope { where(post_type_id: Question.post_type_id) }

  def self.post_type_id
    type_ids = Rails.cache.fetch :post_type_ids do
      PostType.mapping
    end
    type_ids['Answer']
  end

  validates :title, :body, :tags, presence: true
  validate :maximum_tags
  validate :maximum_tag_length
  validate :stripped_minimum

  def answers
    Answer.where(parent: self)
  end

  private
  def maximum_tags
    if tags.length > 5
      errors.add(:tags, "can't have more than 5 tags")
    elsif tags.length < 1
      errors.add(:tags, "must have at least one tag")
    end
  end

  def maximum_tag_length
    tags.each do |tag|
      if tag.length > 20
        errors.add(:tags, "can't be more than 20 characters long each")
      end
    end
  end

  def stripped_minimum
    if body.squeeze(" 	").length < 30
      errors.add(:body, "must be more than 30 non-whitespace characters long")
    end
    if title.squeeze(" 	").length < 15
      errors.add(:title, "must be more than 15 non-whitespace characters long")
    end
  end
end