module UserSortable
  extend ActiveSupport::Concern

  class_methods do
    # Sort a collection according to a user selection, by mapping user selectable values to column names.
    # SQL injection safe.
    # @param term_opts Hash of search term options
    # @param field_mappings Hash of user-selectable values to column names: +{ age: :created_at, rep: :threshold }+
    # @option term_opts :term [String] A user-provided search term to apply - usually from +params+, e.g. +params[:sort]+.
    #   Should be one of the keys in +field_mappings+.
    # @option term_opts :default [Symbol] A column name to apply as the default sort ordering.
    # @return [ActiveRecord::Relation] A relation of the current type, with the sort ordering applied.
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
end
