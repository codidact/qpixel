require 'base64'

class WarningTemplate < ApplicationRecord
  include CommunityRelated

  validates :name, uniqueness: { scope: [:community_id] }

  def body_as_b64
    body_with_site_replacements = body.gsub '$SiteName', SiteSetting['SiteName']

    chat_link = if SiteSetting['ChatLink'].nil?
                  'chat'
                else
                  "[chat](#{SiteSetting['ChatLink']})"
                end
    body_with_site_replacements = body_with_site_replacements.gsub '$ChatLink', chat_link

    Base64.encode64(body_with_site_replacements)
  end
end
