module PostTypesHelper
  def post_type_badge(type)
    icon_class = {
      'Question' => 'fas fa-question',
      'Article' => 'fas fa-newspaper'
    }[type]
    tag.span class: 'badge is-tag is-filled is-muted' do
      tag.i(class: icon_class) + ' ' + tag.span(type) # rubocop:disable Style/StringConcatenation
    end
  end

  def post_type_criteria
    PostType.new.attributes.keys.select { |k| k.start_with?('has_') || k.start_with?('is_') }.map(&:to_sym)
  end

  def post_type_ids(**opts)
    key = post_type_criteria.map { |a| opts[a] ? '1' : '0' }.join
    Rails.cache.fetch "post_type_ids/#{key}" do
      PostType.where(**opts).select(:id).map(&:id)
    end
  end
end
