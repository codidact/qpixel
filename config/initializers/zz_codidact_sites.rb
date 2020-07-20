Rails.cache.persistent 'codidact_sites', clear: true do
  # Do not show codidact_sites for development
  # (allows offline dev)
  if Rails.env.development?
    []
  else
    response = Net::HTTP.get_response(URI('https://codidact.com/communities.json'))
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.fatal "Couldn't fetch Codidact sites: response code #{response.code}"
      exit 255
    end
  end
end
