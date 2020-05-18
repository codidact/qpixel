class APIImport
  def initialize(options)
    @options = options
    @filters = {
      posts: '!)4k)qh2Ywk(NPgBg204EA_3YzAND'
    }
  end

  def request(uri, params)
    params = {
      key: @options.key
    }.merge(params)
    full_uri = URI.parse(uri)
    full_uri.query = params.map { |k, v| "#{k}=#{v}" }.join('&')

    resp = Net::HTTP.get_response(full_uri)
    unless resp.code.start_with? '2'
      $logger.error "#{resp.code} GET #{full_uri.to_s}:"
      $logger.error resp.body
    end

    data = JSON.parse(resp.body)
    if data['backoff']
  end

  # [
  #     [ 0] "id",x
  #     [ 1] "post_type_id",x
  #     [ 2] "accepted_answer_id",
  #     [ 3] "creation_date",x
  #     [ 4] "score",x
  #     [ 5] "view_count",
  #     [ 6] "body",x
  #     [ 7] "owner_user_id",x
  #     [ 8] "last_editor_user_id",x
  #     [ 9] "last_edit_date",x
  #     [10] "last_activity_date",x
  #     [11] "title",x
  #     [12] "tags",
  #     [13] "answer_count",
  #     [14] "comment_count"x
  # ]

  def posts(ids)

  end
end