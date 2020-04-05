class HelpDoc < Post
  def self.post_type_id
    PostType.mapping['HelpDoc']
  end
end
