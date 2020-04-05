module SearchHelper
  def parse_search(raw_search)
    qualifiers_regex = /(\w+(?<!\\):[^ ]+)/
    qualifiers = raw_search.scan(qualifiers_regex).flatten
    search = raw_search
    qualifiers.each do |q|
      search = search.gsub(q, '')
    end
    search = search.gsub(/\\:/, ':').strip
    { qualifiers: qualifiers, search: search }
  end

  def qualifiers_to_sql(qualifiers)
    valid_value = {
      date: /^[<>=]{0,2}\d+(?:s|m|h|d|w|mo|y)?$/,
      numeric: /^[<>=]{0,2}\d+$/
    }

    clauses = qualifiers.map do |qualifier|
      splat = qualifier.split ':'
      parameter = splat[0]
      value = splat[1]

      case parameter
      when 'score'
        next unless value =~ valid_value[:numeric]

        operator, val = numeric_value_sql value
        ["score #{operator.present? ? operator : '='} ?", val.to_i]
      when 'created'
        next unless value =~ valid_value[:date]

        operator, val, timeframe = date_value_sql value
        ["created_at #{operator.present? ? operator : '='} DATE_SUB(CURRENT_TIMESTAMP, INTERVAL ? #{timeframe})",
         val.to_i]
      when 'user'
        next unless value =~ valid_value[:numeric]

        operator, val = numeric_value_sql value
        ["user_id #{operator.present? ? operator : '='} ?", val.to_i]
      end
    end.compact

    sql = clauses.map do |clause|
      ActiveRecord::Base.sanitize_sql clause
    end.join(' AND ')

    Arel.sql(sql)
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
