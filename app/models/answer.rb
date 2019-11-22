class Answer < Post
  default_scope { where(post_type_id: Answer.post_type_id) }

  def self.post_type_id
    type_ids = Rails.cache.fetch :post_type_ids do
      PostType.mapping
    end
    type_ids['Answer']
  end
end
