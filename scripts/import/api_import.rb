class APIImport
  def initialize(options)
    @options = options
    @filters = {
      posts: '!)4k-FmSF0IDnEJZS2CCHzTx9)0VD',
      questions: '!-MOiN_e9QlHG7Z-blYG54Tx0UIt0fJoL9',
      answers: '!SWJ_aFipee(LVrV(mP',
      users: '!)sb2*WuVIS_)ybx(_xTP'
    }
  end

  def request(uri, params = {})
    params = {
      key: @options.key,
      site: @options.site
    }.merge(params)
    full_uri = URI.parse(uri)
    full_uri.query = params.map { |k, v| "#{k}=#{v}" }.join('&')

    if @backoff.present? && @backoff.future?
      seconds = ((@backoff - DateTime.now) * 86400) + 1
      $logger.debug "Waiting #{seconds.to_i}s for backoff"
      sleep seconds.to_i
    end

    resp = Net::HTTP.get_response(full_uri)
    if resp.code.start_with? '2'
      $logger.debug "#{resp.code} GET #{full_uri.to_s}"
    else
      $logger.error "#{resp.code} GET #{full_uri.to_s}:"
      $logger.error resp.body
    end

    data = JSON.parse(resp.body)
    if data['backoff']
      @backoff = DateTime.now + data['backoff'].to_i.seconds
    end

    data
  end

  def posts(ids)
    groups = ids.in_groups_of(100).map(&:compact)
    posts = []
    groups.each do |group|
      posts = posts.concat request("https://api.stackexchange.com/2.2/posts/#{group.join(';')}",
                                   filter: @filters[:posts], pagesize: '100')['items']
    end

    keyed = posts.map do |post|
      [post['post_id'], {
        'id' => post['post_id'],
        'post_type_id' => { 'question' => 1, 'answer' => 2 }[post['post_type']],
        'creation_date' => Time.at(post['creation_date']).iso8601,
        'score' => post['score'],
        'body' => post['body'],
        'owner_user_id' => post['owner']&.try(:[], 'user_id'),
        'last_editor_user_id' => post['last_editor']&.try(:[], 'user_id'),
        'last_edit_date' => Time.at(post['last_edit_date'] || post['creation_date']).iso8601,
        'last_activity_date' => Time.at(post['last_activity_date'] || post['creation_date']).iso8601,
        'title' => post['title']
      }]
    end.to_h

    questions = keyed.values.select { |p| p['post_type_id'] == 1 }
    question_ids = questions.map { |q| q['id'] }
    question_groups = question_ids.in_groups_of(100).map(&:compact)
    question_groups.each do |qg|
      data = request("https://api.stackexchange.com/2.2/questions/#{qg.join(';')}",
                     filter: @filters[:questions], pagesize: '100')['items']
      data.each do |question|
        keyed[question['question_id']] = keyed[question['question_id']].merge({
          'answer_count' => question['answer_count'],
          'tags' => "<#{question['tags'].join('><')}>"
        })
      end
    end

    answers = keyed.values.select { |p| p['post_type_id'] == 2 }
    answer_ids = answers.map { |a| a['id'] }

    answer_groups = answer_ids.in_groups_of(100).map(&:compact)
    answer_groups.each do |ag|
      data = request("https://api.stackexchange.com/2.2/answers/#{ag.join(';')}",
                     filter: @filters[:answers], pagesize: '100')['items']
      data.each do |answer|
        keyed[answer['answer_id']] = keyed[answer['answer_id']].merge({
          'parent_id' => answer['question_id']
        })
      end
    end

    keyed.values
  end

  def users(ids)
    groups = ids.in_groups_of(100).map(&:compact)
    users = []
    groups.each do |group|
      users = users.concat request("https://api.stackexchange.com/2.2/users/#{group.join(';')}",
                                   filter: @filters[:users], pagesize: '100')['items']
    end

    users.each.with_index do |user, idx|
      users[idx] = {
        'id' => user['user_id'],
        'creation_date' => Time.at(user['creation_date']).iso8601,
        'display_name' => user['display_name'],
        'website_url' => user['website_url'],
        'account_id' => user['account_id']
      }
    end

    users
  end
end