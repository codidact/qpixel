require 'ostruct'
require 'optparse'
require 'open-uri'

@options = OpenStruct.new
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: rails r stack_import.rb [options]"

  opts.on('-s', '--site=SITE', "Stack Exchange site API parameter to operate on") do |site|
    @options.site = site
  end

  opts.on('-k', '--key=KEY', 'Stack Exchange API key') do |key|
    @options.key = key
  end

  opts.on('-u', '--user=USER', 'Import only questions from a specified user ID') do |user|
    @options.user = user
  end

  opts.on('-t', '--tag=TAG', 'Import only questions (with their answers) from a specified tag') do |tag|
    @options.tag = tag
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end
opt_parser.parse!

unless @options.site.present? && @options.key.present?
  puts "[FATAL] Site and key must be specified"
  puts
  puts opt_parser.to_s
  exit
end

SYSTEM_USER = User.find(-1)
USER_ID_MAP = {}

def get_data(uri, params)
  page = 1
  params['pagesize'] = 100
  params['key'] = @options.key
  params['site'] = @options.site
  has_more = true
  returns = []
  items = []

  while has_more
    full_uri = uri + '?' + params.map { |k, v| "#{k.to_s}=#{v.to_s}" }.join('&')
    data = JSON.parse(open(full_uri).read)
    received_at = DateTime.now

    if block_given?
      returns << yield(data['items'])
    else
      items.concat data['items']
    end

    if data['backoff'].present?
      sleep_until = received_at + data['backoff'].seconds
      sleep_seconds = sleep_until - DateTime.now
      puts "backing off #{sleep_seconds}s"
      sleep sleep_seconds
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

def create_user(shallow_user)
  # Filter used to get shallow_user should include display_name, link and user_id fields.
  user_id = shallow_user['user_id']

  unless user_id
    return SYSTEM_USER
  end

  if USER_ID_MAP.include? user_id
    account_id = USER_ID_MAP[user_id]
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
    USER_ID_MAP[user_id] = user['account_id']
    puts "created user #{u.id}"
    u
  end
end

def create_post(post_type_id, stack_json, parent_id=nil)
  # Filter used to get stack_json should include (answers), body, body_markdown, (closed_date), creation_date,
  # down_vote_count, last_activity_date, owner, (title), (tags), up_vote_count, link
  params = {post_type_id: post_type_id, body: stack_json['body'], body_markdown: stack_json['body_markdown'],
            created_at: stack_json['creation_date'], last_activity: stack_json['last_activity_date'],
            att_source: stack_json['link'], att_license_name: 'CC BY-SA 4.0',
            att_license_link: 'https://creativecommons.org/licenses/by-sa/4.0/'}

  if stack_json['closed_date'].present?
    params = params.merge(closed: true, closed_by: SYSTEM_USER, closed_at: stack_json['closed_date'])
  end

  if stack_json['title'].present?
    params = params.merge(title: CGI.unescape_html(stack_json['title']))
  end

  if stack_json['tags'].present?
    params = params.merge(tags_cache: stack_json['tags'])
  end

  if parent_id.present?
    params = params.merge(parent_id: parent_id)
  end

  user = create_user stack_json['owner']
  params['user_id'] = user.id

  post = Post.create params
  Vote.create([{post_id: post.id, user: SYSTEM_USER, recv_user: user, vote_type: -1}] * stack_json['down_vote_count'] +
              [{post_id: post.id, user: SYSTEM_USER, recv_user: user, vote_type: 1}] * stack_json['up_vote_count'])
  post
end

def create_question(stack_json)
  create_post Question.post_type_id, stack_json
end

def create_answer(parent_id, stack_json)
  stack_json['title'] = nil
  create_post Answer.post_type_id, stack_json, parent_id
end

data_uri, params = if @options.user.present?
                     ["https://api.stackexchange.com/2.2/users/#{@options.user}/questions",
                      {filter: '!FRQ4VTQp2su7)pS5ZMF4xs7LvHDOch0tf*Xw0bzhr2C8QSBKhCzTFTOSUrhHg)OkIuzNxhOD', sort: 'votes'}]
                   elsif @options.tag.present?
                     ["https://api.stackexchange.com/2.2/questions",
                      {tagged: @options.tag, filter: '!FRQ4VTQp2su7)pS5ZMF4xs7LvHDOch0tf*Xw0bzhr2C8QSBKhCzTFTOSUrhHg)OkIuzNxhOD',
                       sort: 'votes'}]
                   else
                     ["https://api.stackexchange.com/2.2/questions",
                      {filter: '!FRQ4VTQp2su7)pS5ZMF4xs7LvHDOch0tf*Xw0bzhr2C8QSBKhCzTFTOSUrhHg)OkIuzNxhOD', sort: 'votes'}]
                   end

get_data data_uri, params do |items|
  items.each do |item|
    q = create_question item
    puts "created question #{q.id}"
    if item['answers'].present?
      item['answers'].each do |answer|
        a = create_answer q.id, answer
        puts "  with answer #{a.id}"
      end
    end
  end
end