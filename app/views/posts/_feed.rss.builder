posts.each do |post|
  xml.entry do
    xml.id generic_show_link(post)
    xml.title post.title
    xml.author do
      xml.name post.user.username
      xml.uri user_url(post.user)
    end
    xml.published post.created_at&.iso8601
    xml.updated post.last_activity&.iso8601
    xml.link href: generic_show_link(post)
    xml.summary post.body.truncate(200), type: 'html'
  end
end
