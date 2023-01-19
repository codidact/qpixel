# Provides helper methods to determine whether this site is part of the codidact network
module CodidactHelper
  # Whether this server is part of the codidact network.
  def codidact?
    Rails.cache.fetch 'is_codidact' do
      Rails.env.development? ||
        RequestContext.community.host.include?('.codidact.com') ||
        RequestContext.community.host.include?('.codidact.org')
    end
  end
end