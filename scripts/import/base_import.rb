class BaseImport
  def initialize(options, dump_importer, api_importer)
    @options = options
    @dump = dump_importer
    @api = api_importer

    @system_user = User.find(-1)

    @user_id_map = {}
    @post_id_map = {}
  end

  def import(id_map)
    $logger.info "Importing #{id_map.size} posts"
    id_map.each do |info|
      import_post info[0], info[1]
    end
    $logger.info "#{id_map.size} posts imported"
  end

  def import_post(post_id, post_type_id)
    return if @post_id_map.include? post_id.to_i
    return unless [1, 2].include? post_type_id.to_i

    dump_matches = @dump.posts.select { |p| p.id.to_s == post_id }
    if dump_matches.size > 0
      $logger.debug "SEID #{post_id}: in dump"
      post = dump_matches[0]
      post_data = @dump.post_data(post)

      if post.post_type_id == '1'
        native_post = create_question(post_data)
        @post_id_map[post_id.to_i] = native_post.id
      elsif post.post_type_id == '2'
        se_parent_id = post.parent_id
        unless @post_id_map.include? se_parent_id
          import_post se_parent_id, '1'
        end
        native_post = create_answer(@post_id_map[se_parent_id], post_data)
        @post_id_map[post_id.to_i] = native_post.id
      else
        $logger.debug "Not importing SEID #{post_id}: PostTypeId #{post.post_type_id}"
        return
      end
      $logger.debug "SEID #{post_id}: imported (dump) as #{native_post.id}"
    else
      $logger.debug "SEID #{post_id}: get from API"
      post_data = @api.post(post_id, post_type_id)
      if post_type_id.to_s == '1'
        native_post = create_question(post_data)
        @post_id_map[post_id.to_i] = native_post.id
      elsif post_type_id.to_s == '2'
        se_parent_id = post_data['question_id']
        unless @post_id_map.include? se_parent_id
          import_post se_parent_id, '1'
        end
        native_post = create_answer(@post_id_map[se_parent_id], post_data)
        @post_id_map[post_id.to_i] = native_post.id
      else
        $logger.debug "Not importing SEID #{post_id}: PostTypeId #{post_type_id}"
        return
      end
      $logger.debug "SEID #{post_id}: imported (API) as #{native_post.id}"
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
    rescue => ex
      $logger.error "Failed to get license for #{created_at.inspect}: #{ex.message}"
    end
  end

  # shallow_user format:
  # { display_name: string, link: string, user_id: integer, account_id: integer? }
  def create_user(shallow_user)
    # Filter used to get shallow_user should include display_name, link and user_id fields.
    user_id = shallow_user['user_id']

    unless user_id
      return @system_user
    end

    if @user_id_map.include?(user_id)
      account_id = @user_id_map[user_id]
    elsif shallow_user.include?('account_id')
      account_id = shallow_user['account_id']
      user = shallow_user
    else
      dump_matches = @dump.users.select { |u| u.id.to_s == user_id.to_s }
      if dump_matches.size > 0
        user = dump_matches[0].to_h.deep_stringify_keys
        account_id = user['account_id']
      else
        items = @api.get_data "https://api.stackexchange.com/2.2/users/#{user_id}", {filter: '!bWUXTP2WcYJKcm'}
        user = items.first
        account_id = items.first['account_id']
      end
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
      @user_id_map[user_id] = user['account_id']
      $logger.debug "Created user #{u.id} from SE acct #{account_id}"
      u
    end
  end

  # post_data format:
  # { answers: (string | post_data)[]?, body: string, body_markdown: string, closed_date: integer?, creation_date: integer,
  #   down_vote_count: integer, last_activity_date: integer, owner: shallow_user, title: string?, tags: string[]?,
  #   up_vote_count: integer, link: string }
  def create_post(post_type_id, post_data, parent_id=nil)
    # Filter used to get post_data should include (answers), body, body_markdown, (closed_date), creation_date,
    # down_vote_count, last_activity_date, owner, (title), (tags), up_vote_count, link
    post_data = post_data.deep_stringify_keys
    params = {post_type_id: post_type_id, body: post_data['body'], body_markdown: post_data['body_markdown'],
              created_at: post_data['creation_date'], last_activity: post_data['last_activity_date'],
              att_source: post_data['link']}.merge(get_license(post_data['creation_date']))

    if post_data['closed_date'].present?
      params = params.merge(closed: true, closed_by: @system_user, closed_at: post_data['closed_date'])
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
    user.ensure_community_user!
    params['user_id'] = user.id

    category = Category.unscoped.where(community_id: @options.community, name: 'Main').first
    post = Post.create params.merge(community_id: @options.community, category: category)

    vote = { post_id: post.id, user: @system_user, recv_user: user, community_id: @options.community }
    Vote.create([vote.merge(vote_type: -1)] * post_data['down_vote_count'] +
                [vote.merge(vote_type: 1)] * post_data['up_vote_count'])

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