class Question < Post
  default_scope { where(post_type_id: Question.post_type_id) }

  scope :meta, -> { joins(:category).where(categories: { name: 'Meta' }) }
  scope :main, -> { joins(:category).where(categories: { name: 'Main' }) }

  def self.post_type_id
    PostType.mapping['Question']
  end

  def answers
    Answer.where(parent: self)
  end
end
