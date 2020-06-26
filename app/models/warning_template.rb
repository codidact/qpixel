require 'base64'

class WarningTemplate < ApplicationRecord
  include CommunityRelated

  def body_as_b64
    body_with_site_replacements = body.gsub '$SiteName', SiteSetting['SiteName']

    if SiteSetting['ChatLink'].nil?
      body_with_site_replacements = body_with_site_replacements.gsub '$ChatLink', 'chat'
    else
      body_with_site_replacements = body_with_site_replacements.gsub '$ChatLink', '[chat](' + SiteSetting['ChatLink'] + ')'
    end

    Base64.encode64(body_with_site_replacements)
  end
end
