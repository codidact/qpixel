class Question < Post
  default_scope { where(post_type_id: 1) }
end