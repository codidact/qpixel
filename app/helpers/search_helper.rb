module SearchHelper
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

  def qualifiers_to_sql(qualifiers, query)
    valid_value = {
      date: /^[<>=]{0,2}\d+(?:s|m|h|d|w|mo|y)?$/,
      numeric: /^[<>=]{0,2}\d+$/
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
      end
    end

    query
  end

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
