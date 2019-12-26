class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.fuzzy_search(term, **cols)
    sanitized = sanitize_for_search term, **cols
    select(Arel.sql("`#{table_name}`.*, #{sanitized} AS search_score"))
  end

  def self.match_search(term, **cols)
    sanitized = sanitize_for_search term, **cols
    select(Arel.sql("`#{table_name}`.*, #{sanitized} AS search_score")).where(sanitized)
  end

  def self.sanitize_name(name)
    name.to_s.delete('`').insert(0, '`').insert(-1, '`')
  end

  def match_search(term, **cols)
    ApplicationRecord.match_search(term, **cols)
  end

  def user_sort(term_opts, **params)
    default = term_opts[:default] || :created_at
    requested = term_opts[:term]
    direction = term_opts[:direction] || :desc
    if requested.nil? || !params.include?(requested&.to_sym)
      sort(default => direction)
    else
      sort(params[requested&.to_sym] => direction)
    end
  end

  private

  def self.sanitize_for_search(term, **cols)
    cols = cols.map do |k, v|
      if v.is_a?(Array)
        v.map { |vv| "#{sanitize_name k}.#{sanitize_name vv}" }.join(', ')
      else
        "#{sanitize_name k}.#{sanitize_name v}"
      end
    end.join(', ')

    ActiveRecord::Base.send(:sanitize_sql_array, ["MATCH (#{cols}) AGAINST (? IN BOOLEAN MODE)", term])
  end
end