module SearchQualifierHelper
  def matches_date?(value)
    value.match?(/^[<>=]{0,2}[\d.]+(?:s|m|h|d|w|mo|y)?$/)
  end

  def matches_id?(value)
    value.match?(/^[<>=]{0,2}\d+$/)
  end

  def matches_int?(value)
    value.match?(/^[<>=]{0,2}-?\d+$/)
  end

  def matches_numeric?(value)
    value.match?(/^[<>=]{0,2}[\d.]+$/)
  end

  def matches_non_negative_int?(value)
    value.match?(/^[<>=]{0,2}\d+$/)
  end

  def matches_status?(value)
    value.match?(/any|open|closed/)
  end

  def parse_answers_qualifier(value)
    return unless matches_non_negative_int?(value)

    operator, val = numeric_value_sql(value)

    { param: :answers, operator: operator.presence || '=', value: val.to_i }
  end

  def parse_category_qualifier(value)
    return unless matches_id?(value)

    operator, val = numeric_value_sql(value)

    { param: :category, operator: operator.presence || '=', category_id: val.to_i }
  end

  def parse_created_qualifier(value)
    return unless matches_date?(value)

    operator, val, timeframe = date_value_sql(value)

    { param: :created, operator: operator.presence || '=', timeframe: timeframe, value: val.to_i }
  end

  def parse_downvotes_qualifier(value)
    return unless matches_non_negative_int?(value)

    operator, val = numeric_value_sql(value)

    { param: :downvotes, operator: operator.presence || '=', value: val.to_i }
  end

  def parse_exclude_tag_qualifier(value)
    { param: :exclude_tag, tag_id: Tag.where(name: value).select(:id) }
  end

  def parse_post_type_qualifier(value)
    return unless matches_id?(value)

    operator, val = numeric_value_sql(value)

    { param: :post_type, operator: operator.presence || '=', post_type_id: val.to_i }
  end

  def parse_score_qualifier(value)
    return unless matches_numeric?(value)

    operator, val = numeric_value_sql(value)

    { param: :score, operator: operator.presence || '=', value: val.to_f }
  end

  def parse_status_qualifier(value)
    return unless matches_status?(value)

    { param: :status, value: value }
  end

  def parse_include_tag_qualifier(value)
    { param: :include_tag, tag_id: Tag.where(name: value).select(:id) }
  end

  def parse_upvotes_qualifier(value)
    return unless matches_non_negative_int?(value)

    operator, val = numeric_value_sql(value)

    { param: :upvotes, operator: operator.presence || '=', value: val.to_i }
  end

  def parse_user_qualifier(value)
    return unless matches_int?(value) || value == 'me'

    operator, val = if value == 'me'
                      ['=', current_user&.id]
                    else
                      numeric_value_sql(value)
                    end

    { param: :user, operator: operator.presence || '=', user_id: val.to_i }
  end

  def parse_votes_qualifier(value)
    return unless matches_int?(value)

    operator, val = numeric_value_sql(value)

    { param: :net_votes, operator: operator.presence || '=', value: val.to_i }
  end

  # Parses a qualifier value string, including operator, as a numeric value.
  # @param value [String] The value part of the qualifier, i.e. +">=10"+
  # @return [Array(String, String)] A 2-tuple containing operator and value.
  # @api private
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

  # Parses a qualifier value string, including operator, as a date value.
  # @param value [String] The value part of the qualifier, i.e. +">=10d"+
  # @return [Array(String, String, String)] A 3-tuple containing operator, value, and timeframe.
  # @api private
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
