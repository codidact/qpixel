class BaseImport
  def new(options)
    @options = options
  end

  def import_post(post_id)
    raise NotImplementedError
  end

  def site_base_url
    site_param = @options.site
    non_se = {stackoverflow: 'com', superuser: 'com', serverfault: 'com', askubuntu: 'com', mathoverflow: 'net', stackapps: 'com'}
    included = non_se.keys.map(&:to_s).select { |k| site_param.include? k }
    if included.size > 0
      "https://#{included[0]}.#{non_se[included[0]]}"
    else
      "https://#{site_param}.stackexchange.com"
    end
  end

  def get_license(created_at)
    if created_at.is_a? String
      created_at = Date.parse(created_at)
    elsif created_at.is_a? Integer
      created_at = Time.at(created_at).to_datetime
    end

    begin
      if created_at < Date.new(2019, 9, 5)
        { att_license_name: 'CC BY-SA 3.0', att_license_link: 'https://creativecommons.org/licenses/by-sa/3.0/' }
      else
        { att_license_name: 'CC BY-SA 4.0', att_license_link: 'https://creativecommons.org/licenses/by-sa/4.0/' }
      end
    rescue
      puts "oh noes"
    end
  end

  # shallow_user format:
  # { display_name: string, link: string, user_id: integer, account_id: integer? }
  def create_user(shallow_user)
    # Filter used to get shallow_user should include display_name, link and user_id fields.
    user_id = shallow_user['user_id']

    unless user_id
      return $system_user
    end

    if $user_id_map.include?(user_id)
      account_id = $user_id_map[user_id]
    elsif shallow_user.include?('account_id')
      account_id = shallow_user['account_id']
      user = shallow_user
    else
      items = get_data "https://api.stackexchange.com/2.2/users/#{user_id}", {filter: '!bWUXTP2WcYJKcm'}
      user = items.first
      account_id = items.first['account_id']
    end
    existing = User.where(se_acct_id: account_id)
    if existing.size > 0
      existing.first
    else
      profile_text = "This user was automatically created as the author of content sourced from Stack Exchange.\n\n" +
          "The original profile on Stack Exchange can be found here: <#{shallow_user['link']}>."
      u = User.create(password: SecureRandom.hex(64), email: "#{user['account_id']}@synthetic-oauth.localhost",
                      username: CGI.unescape_html(user['display_name']), se_acct_id: user['account_id'],
                      profile_markdown: profile_text, profile: QuestionsController.renderer.render(profile_text))
      $user_id_map[user_id] = user['account_id']
      puts "created user #{u.id}"
      u
    end
  end

  # post_data format:
  # { answers: post_data[]?, body: string, body_markdown: string, closed_date: integer?, creation_date: integer,
  #   down_vote_count: integer, last_activity_date: integer, owner: shallow_user, title: string?, tags: string[]?,
  #   up_vote_count: integer, link: string }
  def create_post(post_type_id, post_data, parent_id=nil)
    # Filter used to get post_data should include (answers), body, body_markdown, (closed_date), creation_date,
    # down_vote_count, last_activity_date, owner, (title), (tags), up_vote_count, link
    params = {post_type_id: post_type_id, body: post_data['body'], body_markdown: post_data['body_markdown'],
              created_at: post_data['creation_date'], last_activity: post_data['last_activity_date'],
              att_source: post_data['link']}.merge(get_license(post_data['creation_date']))

    if post_data['closed_date'].present?
      params = params.merge(closed: true, closed_by: $system_user, closed_at: post_data['closed_date'])
    end

    if post_data['title'].present?
      params = params.merge(title: CGI.unescape_html(post_data['title']))
    end

    if post_data['tags'].present?
      params = params.merge(tags_cache: post_data['tags'])
    end

    if parent_id.present?
      params = params.merge(parent_id: parent_id)
    end

    user = create_user post_data['owner']
    params['user_id'] = user.id

    post = Post.create params
    Vote.create([{post_id: post.id, user: $system_user, recv_user: user, vote_type: -1}] * post_data['down_vote_count'] +
                    [{post_id: post.id, user: $system_user, recv_user: user, vote_type: 1}] * post_data['up_vote_count'])
    post
  end

  def create_question(post_data)
    create_post Question.post_type_id, post_data
  end

  def create_answer(parent_id, post_data)
    post_data['title'] = nil
    create_post Answer.post_type_id, post_data, parent_id
  end
end