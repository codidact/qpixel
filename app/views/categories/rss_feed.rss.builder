xml.instruct! :xml, version: '1.0'
xml.feed xmlns: 'http://www.w3.org/2005/Atom' do
  xml.id category_feed_url(@category)
  xml.title "New Posts - #{@category.name} - #{SiteSetting['SiteName']}"
  xml.author do
    xml.name "#{SiteSetting['SiteName']} - Codidact"
  end
  xml.link nil, rel: 'self', href: category_url(@category)
  xml.updated @posts.maximum(:last_activity)&.iso8601 || RequestContext.community.created_at&.iso8601

  @posts.each do |post|
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
end
