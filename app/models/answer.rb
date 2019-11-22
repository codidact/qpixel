class Answer < Post
  default_scope { where(post_type_id: Answer.post_type_id) }

  def self.post_type_id
    PostType.mapping['Answer']
  end
end
