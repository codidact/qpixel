module SearchHelper
  def search_posts
    # Check permissions
    posts = (current_user&.is_moderator || current_user&.is_admin ? Post : Post.undeleted)
            .qa_only.list_includes

    # Filter based on search string qualifiers
    if params[:search].present?
      search_data = parse_search(params[:search])
      posts = qualifiers_to_sql(search_data[:qualifiers], posts)
    end

    posts = filters_to_sql(posts)

    posts = posts.paginate(page: params[:page], per_page: 25)

    if params[:search].present? && search_data[:search].present?
      posts.search(search_data[:search]).user_sort({ term: params[:sort], default: :search_score },
                                                   relevance: :search_score, score: :score, age: :created_at)
    else
      posts.user_sort({ term: params[:sort], default: :score },
                      score: :score, age: :created_at)
    end
  end

  def filters_to_sql(query)
    valid_value = {
      date: /^[\d.]+(?:s|m|h|d|w|mo|y)?$/,
      numeric: /^[\d.]+$/
    }

    if params[:filter_score_min]&.match?(valid_value[:numeric])
      query = query.where('score >= ?', params[:filter_score_min].to_f)
    end

    if params[:filter_score_max]&.match?(valid_value[:numeric])
      query = query.where('score <= ?', params[:filter_score_max].to_f)
    end

    query
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
  def qualifiers_to_sql(qualifiers, query)
    valid_value = {
      date: /^[<>=]{0,2}[\d.]+(?:s|m|h|d|w|mo|y)?$/,
      numeric: /^[<>=]{0,2}[\d.]+$/
    }

    qualifiers.each do |qualifier| # rubocop:disable Metrics/BlockLength
      splat = qualifier.split ':'
      parameter = splat[0]
      value = splat[1]

      case parameter
      when 'score'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        query = query.where("score #{operator.presence || '='} ?", val.to_f)
      when 'created'
        next unless value.match?(valid_value[:date])

        operator, val, timeframe = date_value_sql value
        query = query.where("created_at #{operator.presence || '='} DATE_SUB(CURRENT_TIMESTAMP, " \
                            "INTERVAL ? #{timeframe})",
                            val.to_i)
      when 'user'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        query = query.where("user_id #{operator.presence || '='} ?", val.to_i)
      when 'upvotes'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        query = query.where("upvotes #{operator.presence || '='} ?", val.to_i)
      when 'downvotes'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        query = query.where("downvotes #{operator.presence || '='} ?", val.to_i)
      when 'votes'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        query = query.where("(upvotes - downvotes) #{operator.presence || '='}", val.to_i)
      when 'tag'
        query = query.where(posts: { id: PostsTag.where(tag_id: Tag.where(name: value).select(:id)).select(:post_id) })
      when '-tag'
        query = query.where.not(posts: { id: PostsTag.where(tag_id: Tag.where(name: value).select(:id))
                                                     .select(:post_id) })
      when 'category'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        trust_level = current_user&.trust_level || 0
        allowed_categories = Category.where('IFNULL(min_view_trust_level, -1) <= ?', trust_level)
        query = query.where("category_id #{operator.presence || '='} ?", val.to_i)
                     .where(category_id: allowed_categories)
      when 'post_type'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        query = query.where("post_type_id #{operator.presence || '='} ?", val.to_i)
      when 'answers'
        next unless value.match?(valid_value[:numeric])

        operator, val = numeric_value_sql value
        post_types_with_answers = PostType.where(has_answers: true)
        query = query.where("answer_count #{operator.presence || '='} ?", val.to_i)
                     .where(post_type_id: post_types_with_answers)
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
