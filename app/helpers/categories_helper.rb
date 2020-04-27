module CategoriesHelper
  def active?(category)
    current_page?(category_path(category)) || (category.is_homepage && current_page?(root_path))
  end
end
