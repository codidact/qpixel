class ArticlesController < ApplicationController
  before_action :set_article
  before_action :check_article

  def share
    redirect_to article_path(params[:id])
  end

  private

  def set_article
    @article = Article.find params[:id]
    if @article.deleted && !current_user&.has_post_privilege?('flag_curate', @article)
      not_found
    end
  end

  def check_article
    unless @article.post_type_id == Article.post_type_id
      not_found
    end
  end
end
