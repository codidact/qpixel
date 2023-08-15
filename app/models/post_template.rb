class PostTemplate < Post
  def self.post_type_id
    PostType.mapping['PostTemplate']
  end
end
