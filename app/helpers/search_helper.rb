module SearchHelper
  def search_posts
    # Check permissions
    posts = (current_user&.is_moderator || current_user&.is_admin ? Post : Post.undeleted)
            .qa_only.list_includes

    qualifiers = filters_to_qualifiers
    search_string = params[:search]

    # Filter based on search string qualifiers
    if search_string.present?
      search_data = parse_search(search_string)
      qualifiers += parse_qualifier_strings search_data[:qualifiers]
      search_string = search_data[:search]
    end

    posts = qualifiers_to_sql(qualifiers, posts)
    posts = posts.paginate(page: params[:page], per_page: 25)

    if search_string.present?
      posts.search(search_data[:search]).user_sort({ term: params[:sort], default: :search_score },
                                                   relevance: :search_score, score: :score, age: :created_at)
    else
      posts.user_sort({ term: params[:sort], default: :score },
                      score: :score, age: :created_at)
    end
  end

  def filters_to_qualifiers
    valid_value = {
      date: /^[\d.]+(?:s|m|h|d|w|mo|y)?$/,
      status: /any|open|closed/,
      numeric: /^[\d.]+$/,
      integer: /^\d+$/
    }

    filter_qualifiers = []

    if params[:min_score]&.match?(valid_value[:numeric])
      filter_qualifiers.append({ param: :score, operator: '>=', value: params[:min_score].to_f })
    end

    if params[:max_score]&.match?(valid_value[:numeric])
      filter_qualifiers.append({ param: :score, operator: '<=', value: params[:max_score].to_f })
    end

    if params[:min_answers]&.match?(valid_value[:numeric])
      filter_qualifiers.append({ param: :answers, operator: '>=', value: params[:min_answers].to_i })
    end

    if params[:max_answers]&.match?(valid_value[:numeric])
      filter_qualifiers.append({ param: :answers, operator: '<=', value: params[:max_answers].to_i })
    end

    if params[:status]&.match?(valid_value[:status])
      filter_qualifiers.append({ param: :status, value: params[:status] })
    end

    if params[:include_tags]&.all? { |id| id.match? valid_value[:integer] }
      filter_qualifiers.append({ param: :include_tags, tag_ids: params[:include_tags] })
    end

    if params[:exclude_tags]&.all? { |id| id.match? valid_value[:integer] }
      filter_qualifiers.append({ param: :exclude_tags, tag_ids: params[:exclude_tags] })
    end

    filter_qualifiers
  end

  def parse_search(raw_search)
    qualifiers_regex = /([\w\-_]+(?<!\\):[^ ]+)/
    qualifiers = raw_search.scan(qualifiers_regex).flatten
    search = raw_search
    qualifiers.each do |q|
      search = search.gsub(q, '')
    end
    search = search.gsub(/\\:/, ':').strip
    { qualifiers: qualifiers, search: search }
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def parse_qualifier_strings(qualifiers)
    valid_value = {
      date: /^[<>=]{0,2}[\d.]+(?:s|m|h|d|w|mo|y)?$/,
      status: /any|open|closed/,
      numeric: /^[<>=]{0,2}[\d.]+$/
    }

    qualifiers.map do |qualifier| # rubocop:disable Metrics/BlockLength
      splat = qualifier.split ':'
      parameter = splat[0]
      value = splat[1]

      case parameter
      when 'score'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :score, operator: operator.presence || '=', value: val.to_f }
      when 'created'
        next unless value.match?(valid_value[:date])

        operator, val, timeframe = date_value_sql value
        { param: :created, operator: operator.presence || '=', timeframe: timeframe, value: val.to_i }
      when 'user'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :user, operator: operator.presence || '=', user_id: val.to_i }
      when 'upvotes'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :upvotes, operator: operator.presence || '=', value: val.to_i }
      when 'downvotes'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :downvotes, operator: operator.presence || '=', value: val.to_i }
      when 'votes'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :net_votes, operator: operator.presence || '=', value: val.to_i }
      when 'tag'
        { param: :include_tag, tag_id: Tag.where(name: value).select(:id) }
      when '-tag'
        { param: :exclude_tag, tag_id: Tag.where(name: value).select(:id) }
      when 'category'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :category, operator: operator.presence || '=', category_id: val.to_i }
      when 'post_type'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :post_type, operator: operator.presence || '=', post_type_id: val.to_i }
      when 'answers'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        { param: :answers, operator: operator.presence || '=', value: val.to_i }
      when 'status'
        next unless value.match?(valid_value[:status])

        { param: :status, value: value }
      end
    end
  end

  def qualifiers_to_sql(qualifiers, query)
    trust_level = current_user&.trust_level || 0
    allowed_categories = Category.where('IFNULL(min_view_trust_level, -1) <= ?', trust_level)
    query = query.where(category_id: allowed_categories)

    qualifiers.each do |qualifier| # rubocop:disable Metrics/BlockLength
      case qualifier[:param]
      when :score
        query = query.where("score #{qualifier[:operator]} ?", qualifier[:value])
      when :created
        query = query.where("created_at #{qualifier[:operator]} DATE_SUB(CURRENT_TIMESTAMP, " \
                            "INTERVAL ? #{qualifier[:timeframe]})",
                            qualifier[:value])
      when :user
        query = query.where("user_id #{qualifier[:operator]} ?", qualifier[:user_id])
      when :upvotes
        query = query.where("upvote_count #{qualifier[:operator]} ?", qualifier[:value])
      when :downvotes
        query = query.where("downvote_count #{qualifier[:operator]} ?", qualifier[:value])
      when :net_votes
        query = query.where("(upvote_count - downvote_count) #{qualifier[:operator]} ?", qualifier[:value])
      when :include_tag
        query = query.where(posts: { id: PostsTag.where(tag_id: qualifier[:tag_id]).select(:post_id) })
      when :include_tags
        # Efficiency is... questionable
        qualifier[:tag_ids].each do |id|
          query = query.where(id: PostsTag.where(tag_id: id).select(:post_id))
        end
      when :exclude_tag
        query = query.where.not(posts: { id: PostsTag.where(tag_id: qualifier[:tag_id]).select(:post_id) })
      when :exclude_tags
        query = query.where.not(id: PostsTag.where(tag_id: qualifier[:tag_ids]).select(:post_id))
      when :category
        query = query.where("category_id #{qualifier[:operator]} ?", qualifier[:category_id])
      when :post_type
        query = query.where("post_type_id #{qualifier[:operator]} ?", qualifier[:post_type_id])
      when :answers
        post_types_with_answers = PostType.where(has_answers: true)
        query = query.where("answer_count #{qualifier[:operator]} ?", qualifier[:value])
                     .where(post_type_id: post_types_with_answers)
      when :status
        case qualifier[:value]
        when 'open'
          query = query.where(closed: false)
        when 'closed'
          query = query.where(closed: true)
        end
      end
    end

    query
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def numeric_value_sql(value)
    operator = ''
    while ['<', '>', '='].include? value[0]
      operator += value[0]
      value = value[1..-1]
    end

    # whatever's left after stripping operator is the number
    # validated by regex in qualifiers_to_sql
    [operator, value]
  end

  def date_value_sql(value)
    operator = ''

    while ['<', '>', '='].include? value[0]
      operator += value[0]
      value = value[1..-1]
    end

    # working with dates: <1y ('less than one year ago') is SQL: > 1y ago
    operator = { '<' => '>', '>' => '<', '<=' => '>=', '>=' => '<=' }[operator] || ''

    val = ''
    while value[0] =~ /[[:digit:]]/
      val += value[0]
      value = value[1..-1]
    end

    timeframe = { s: 'SECOND', m: 'MINUTE', h: 'HOUR', d: 'DAY', w: 'WEEK', mo: 'MONTH', y: 'YEAR' }[value.to_sym]

    [operator, val, timeframe || 'MONTH']
  end
end
