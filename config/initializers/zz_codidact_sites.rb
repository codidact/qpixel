Rails.cache.persistent 'codidact_sites', clear: true do
  # Do not show codidact_sites for development (allows offline dev)
  # Do not spam codidact.com while running the tests.
  if Rails.env.development? || Rails.env.test?
    []
  else
    uri = URI('https://codidact.com/communities.json')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{Rails.application.credentials.cf_bot_key}"
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Couldn't fetch Codidact sites: response code #{response.code}"
      []
    end
  end
end
