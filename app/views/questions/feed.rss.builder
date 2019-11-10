xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "New Questions - QPixel"
    xml.author "QPixel"
    xml.description "New questions from a QPixel site."
    xml.link "http://#{request.host}"
    xml.language "en"

    @questions.each do |question|
      xml.item do
        xml.title question.title
        xml.author do
          xml.name question.user.username
          xml.uri "http://#{request.host}/users/#{question.user.id}"
        end
        xml.published question.created_at.to_s(:rfc822)
        xml.updated question.updated_at.to_s(:rfc822)
        xml.link href: "http://#{request.host}/questions/#{question.id}"
        xml.summary question.body.truncate(200)
      end
    end
  end
end
