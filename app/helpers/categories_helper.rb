module CategoriesHelper
  def active?(category)
    current_category
    current_page?(category_url(category)) || (category.is_homepage && current_page?(root_url)) ||
      (defined?(@current_category) && @current_category&.id == category.id)
  end

  def expandable?
    (defined?(@category) && !@category&.id.nil? && !current_page?(new_category_url)) ||
      (defined?(@post) && !@post&.category.nil?) ||
      (defined?(@question) && !@question&.category.nil?) ||
      (defined?(@article) && !@article&.category.nil?)
  end

  def current_category
    @current_category ||= if defined?(@category) && !@category&.id.nil?
                            @category
                          elsif defined?(@post) && !@post&.category.nil?
                            @post.category
                          elsif defined?(@question) && !@question&.category.nil?
                            @question.category
                          elsif defined?(@article) && !@article&.category.nil?
                            @article.category
                          end
  end

  def pending_suggestions?
    Rails.cache.fetch "pending_suggestions/#{current_category.id}" do
      SuggestedEdit.where(post: Post.undeleted.where(category: current_category), active: true).any?
    end
  end
end
