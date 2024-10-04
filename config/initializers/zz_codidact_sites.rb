Rails.cache.persistent 'codidact_sites', clear: true do
  # Do not show codidact_sites for development (allows offline dev)
  # Do not spam codidact.com while running the tests.
  if Rails.env.development? || Rails.env.test?
    []
  else
    response = Net::HTTP.get_response(URI('https://codidact.com/communities.json'))
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Couldn't fetch Codidact sites: response code #{response.code}"
      []
    end
  end
end
