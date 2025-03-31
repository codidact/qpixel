module PostTypesHelper
  ##
  # Create a badge to display the specified post type.
  # @param type [PostType]
  # @return [ActiveSupport::SafeBuffer]
  def post_type_badge(type)
    tag.span class: 'badge is-tag is-filled is-muted' do
      "#{tag.i(class: type.icon_name)} #{tag.span(type.name)}"
    end
  end

  ##
  # Get a list of predicate post type attributes (i.e. is_* and has_* attributes).
  # @api private
  # @return [Array<Symbol>]
  def post_type_criteria
    PostType.new.attributes.keys.select { |k| k.start_with?('has_') || k.start_with?('is_') }.map(&:to_sym)
  end

  ##
  # Get a list of post type IDs matching specified criteria. Available criteria are based on predicate attributes on the
  # post_types table (i.e. +has_*+ and +is_*+ attributes).
  # @option opts :has_answers [Boolean]
  # @option opts :has_votes [Boolean]
  # @option opts :has_tags [Boolean]
  # @option opts :has_parent [Boolean]
  # @option opts :has_category [Boolean]
  # @option opts :has_license [Boolean]
  # @option opts :is_public_editable [Boolean]
  # @option opts :is_closeable [Boolean]
  # @option opts :is_top_level [Boolean]
  # @option opts :is_freely_editable [Boolean]
  # @option opts :has_reactions [Boolean]
  # @option opts :has_only_specific_reactions [Boolean]
  # @return [Array<Integer>]
  # @example Query for IDs of top-level post types which are freely editable and have reactions:
  #   helpers.post_type_ids(is_top_level: true, is_freely_editable: true, has_reactions: true)
  #   # => [12, 23, 49]
  def post_type_ids(**opts)
    key = post_type_criteria.map { |a| opts[a] ? '1' : '0' }.join
    Rails.cache.fetch "network/post_types/post_type_ids/#{key}", include_community: false do
      PostType.where(**opts).select(:id).map(&:id)
    end
  end
end
