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

  def self.sanitize_sql_in(ary)
    return '(NULL)' unless ary.present? && ary.respond_to?(:map)

    res = ActiveRecord::Base.sanitize_sql_array([ary.map { |_e| '?' }.join(', '), *ary])
    "(#{res})"
  end

  # This is a BRILLIANT idea. BRILLIANT, I tell you.
  def self.with_lax_group_rules
    return unless block_given?

    transaction do
      connection.execute 'SET @old_sql_mode = @@sql_mode'
      connection.execute "SET SESSION sql_mode = REPLACE(REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY,', ''), " \
                         "'ONLY_FULL_GROUP_BY', '')"
      yield
      connection.execute 'SET SESSION sql_mode = @old_sql_mode'
    end
  end
end

module UserSortable
  # Sort a collection according to a user selection, by mapping user selectable values to column names.
  # SQL injection safe.
  # @param term_opts Hash of search term options: { term: params[:sort], default: :created_at }
  # @param field_mappings Hash of user-selectable values to column names: { age: :created_at, rep: :threshold }
  def user_sort(term_opts, **field_mappings)
    default = term_opts[:default] || :created_at
    requested = term_opts[:term]
    direction = term_opts[:direction] || :desc
    if requested.nil? || !field_mappings.include?(requested.to_sym)
      $active_search_param = default
      default.is_a?(Symbol) ? order(default => direction) : order(default)
    else
      requested_val = field_mappings[requested.to_sym]
      $active_search_param = requested_val
      requested_val.is_a?(Symbol) ? order(requested_val => direction) : order(requested_val)
    end
  end
end

klasses = [::ActiveRecord::Relation]
klasses << if defined? ::ActiveRecord::Associations::CollectionProxy
             ::ActiveRecord::Associations::CollectionProxy
           else
             ::ActiveRecord::Associations::AssociationCollection
           end

ActiveRecord::Base.extend UserSortable
klasses.each { |klass| klass.send(:include, UserSortable) }
