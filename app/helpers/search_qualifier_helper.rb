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
    return unless matches_id?(value) || value == 'me'

    operator, val = if value == 'me'
                      ['=', current_user&.id&.to_i]
                    else
                      numeric_value_sql(value)
                    end

    { param: :user, operator: operator.presence || '=', user_id: val }
  end

  def parse_votes_qualifier(value)
    return unless matches_int?(value)

    operator, val = numeric_value_sql(value)

    { param: :net_votes, operator: operator.presence || '=', value: val.to_i }
  end
end
