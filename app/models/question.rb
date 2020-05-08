class Question < Post
  default_scope { where(post_type_id: Question.post_type_id) }

  scope :meta, -> { joins(:category).where(categories: { name: 'Meta' }) }
  scope :main, -> { joins(:category).where(categories: { name: 'Main' }) }

  belongs_to :close_reason, optional: true
  belongs_to :duplicate_post, class_name: 'Question', optional: true

  def self.post_type_id
    PostType.mapping['Question']
  end

  validates :title, :body, :tags_cache, presence: true
  validate :tags_in_tag_set
  validate :maximum_tags
  validate :maximum_tag_length
  validate :no_spaces_in_tags
  validate :stripped_minimum

  after_save :update_tag_associations

  def answers
    Answer.where(parent: self)
  end
end
