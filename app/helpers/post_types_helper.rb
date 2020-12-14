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
end
