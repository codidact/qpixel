class APIImport
  def initialize(options)
    @options = options
    @backoff = nil
    @cache = OpenStruct.new(posts: [], users: [])

    $logger.info 'Loading basic post set from API'
    get_data('https://api.stackexchange.com/2.2/questions',
             { filter: '!)PBnhGn1BSYvK7)acUqsdh*WzUqRTlx3**rDPG7YMZdpbUENVagLDusGJB6S5vhlXV85.X' }, max=2000) do |items|
      items.each do |question|
        @cache.posts << question.merge('id' => question['question_id'])
        question['answers']&.each do |answer|
          @cache.posts << answer.merge('id' => answer['answer_id'])
        end
      end
    end
  end

  def get_data(uri, params, max=nil)
    params['page'] = 1
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

      full_uri = URI(uri + '?' + params.map { |k, v| "#{k.to_s}=#{v.to_s}" }.join('&'))
      response = Net::HTTP.get_response(full_uri)
      if response.code.start_with? '2'
        $logger.debug "API request [#{response.code}]: #{full_uri}"
      else
        $logger.error "API request [#{response.code}]: #{full_uri}"
        $logger.error response.body
      end
      data = JSON.parse(response.body)
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
      params['page'] += 1

      if max.present? && [items.size, returns.size].max >= max
        break
      end
    end

    if block_given?
      returns
    else
      items
    end
  end
end