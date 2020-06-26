require 'base64'

class WarningTemplate < ApplicationRecord
  include CommunityRelated

  def body_as_b64
    body_with_site_replacements = body.gsub '$SiteName', SiteSetting['SiteName']

    body_with_site_replacements = if SiteSetting['ChatLink'].nil?
      body_with_site_replacements.gsub '$ChatLink', 'chat'
    else
      chat_link = '[chat](' + SiteSetting['ChatLink'] + ')'
      body_with_site_replacements.gsub '$ChatLink', chat_link
    end

    Base64.encode64(body_with_site_replacements)
  end
end
