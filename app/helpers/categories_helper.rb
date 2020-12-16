module CategoriesHelper
  def active?(category)
    current_category
    current_page?(category_path(category)) || (category.is_homepage && current_page?(root_path)) ||
      (defined?(@current_category) && @current_category&.id == category.id)
  end

  def expandable?
    (defined?(@category) && !@category.nil? && !current_page?(new_category_path)) ||
      (defined?(@post) && !@post.category.nil?) ||
      (defined?(@question) && !@question.category.nil?) ||
      (defined?(@article) && !@article.category.nil?)
  end

  def current_category
    @current_category ||= if defined?(@category) && !@category.nil?
                            @category
                          elsif defined?(@post) && !@post.category.nil?
                            @post.category
                          elsif defined?(@question) && !@question.category.nil?
                            @question.category
                          elsif defined?(@article) && !@article.category.nil?
                            @article.category
                          end
  end
end
