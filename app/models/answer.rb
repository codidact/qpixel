class Answer < Post
  default_scope { where(post_type_id: 2) }
end
