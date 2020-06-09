class Article < Post
  default_scope { where(post_type_id: Article.post_type_id) }

  def self.post_type_id
    PostType.mapping['Article']
  end
end
