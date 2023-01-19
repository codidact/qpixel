# Provides helper methods to determine whether this site is part of the codidact network
module CodidactHelper
  # Whether this server is part of the codidact network.
  def codidact?
    Rails.cache.fetch 'is_codidact' do
      Rails.env.development? ||
        RequestContext.community.host.end_with?('.codidact.com') ||
        RequestContext.community.host.end_with?('.codidact.org')
    end
  end
end