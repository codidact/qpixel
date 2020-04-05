class PolicyDoc < Post
  def self.post_type_id
    PostType.mapping['PolicyDoc']
  end
end
