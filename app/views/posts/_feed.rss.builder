posts.each do |post|
  builder.entry do
    builder.id generic_show_link(post)
    builder.title post.title
    builder.author do
      builder.name post.user.username
      builder.uri user_url(post.user)
    end
    builder.published post.created_at&.iso8601
    builder.updated post.last_activity&.iso8601
    builder.link href: generic_show_link(post)
    builder.summary post.body.truncate(200), type: 'html'
  end
end
