class APIImport
  def initialize(options)
    @options = options
    @backoff = nil
  end

  def get_data(uri, params)
    page = 1
    params['pagesize'] = 100
    params['key'] = @options.key
    params['site'] = @options.site
    has_more = true
    returns = []
    items = []

    while has_more
      if !@backoff.nil? && @backoff.future?
        seconds_remaining = @backoff - DateTime.now
        $logger.debug "Backoff has #{seconds_remaining} left"
        sleep seconds_remaining
      end

      full_uri = uri + '?' + params.map { |k, v| "#{k.to_s}=#{v.to_s}" }.join('&')
      data = JSON.parse(Net::HTTP.get_response(full_uri).body)
      received_at = DateTime.now

      if block_given?
        returns << yield(data['items'])
      else
        items.concat data['items']
      end

      if data['backoff'].present?
        sleep_until = received_at + data['backoff'].seconds
        @backoff = sleep_until
      end
      has_more = data['has_more']
      page += 1
    end

    if block_given?
      returns
    else
      items
    end
  end
end