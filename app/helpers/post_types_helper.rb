module PostTypesHelper
  def post_type_badge(type)
    tag.span class: 'badge is-tag is-filled is-muted' do
      tag.i(class: type.icon_name) + ' ' + tag.span(type.name) # rubocop:disable Style/StringConcatenation
    end
  end

  def post_type_criteria
    PostType.new.attributes.keys.select { |k| k.start_with?('has_') || k.start_with?('is_') }.map(&:to_sym)
  end

  def post_type_ids(**opts)
    key = post_type_criteria.map { |a| opts[a] ? '1' : '0' }.join
    Rails.cache.fetch "network/post_types/post_type_ids/#{key}", include_community: false do
      PostType.where(**opts).select(:id).map(&:id)
    end
  end
end
