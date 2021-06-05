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

  def attributes_print
    attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
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

  def self.useful_err_msg
    [
      'The inverted database guide has found an insurmountable problem. Please poke it with a ' \
        'paperclip before anyone finds out.',
      'The modular cable meter has found a problem. You need to kick your IT technician in the ' \
        'shins immediately.',
      'The integral output port has found a problem. Please take it back to the shop and take ' \
        'the rest of the day off.',
      'The integral expansion converter has encountered a terminal error. You must take legal ' \
        'advice urgently.',
      'Congratulations. You have reached the end of the internet.',
      'The Spanish Inquisition raised an unexpected error. Cannot continue without comfy-chair-interrogation.',
      'The server halted in an after-you loop.',
      'A five-level precedence operation shifted too long and cannot be recovered without data loss. ' \
        'Please re-enable the encryption protocol.',
      'The server\'s headache has not improved in the last 24 hours. It needs to be rebooted.',
      'The primary LIFO data recipient is currently on a holiday and will not be back before next Thursday.',
      'The operator is currently trying to solve their Rubik\'s cube. We will come back to you when the ' \
        'second layer is completed.',
      'The encryption protocol offered by the client predates the invention of irregular logarithmic ' \
        'functions.',
      'The data in the secondary (backup) user registry is corrupted and needs to be re-filled with ' \
        'random data again.',
      'This community has reached a critical mass and collapsed into a black hole. Currently trying to ' \
        'recover using Hawking radiation.',
      'Operations are on pause while we attempt to recapture the codidactyl. Please hold.'
    ]
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
    if requested.nil? || field_mappings.exclude?(requested.to_sym)
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
