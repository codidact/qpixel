class ArticlesController < ApplicationController
  before_action :set_article

  def show
    if @article.deleted?
      check_your_privilege('ViewDeleted', @article) # || return
    end
  end

  def share
    redirect_to article_path(params[:id])
  end

  def edit
    check_your_privilege('Edit', @article)
  end

  def update
    return unless check_your_privilege('Edit', @article)

    PostHistory.post_edited(@article, current_user, before: @article.body_markdown,
                            after: params[:article][:body_markdown], comment: params[:edit_comment])
    body_rendered = helpers.render_markdown(params[:article][:body_markdown])
    if @article.update(article_params.merge(tags_cache: params[:article][:tags_cache]&.reject(&:empty?),
                                            body: body_rendered, last_activity: DateTime.now,
                                            last_activity_by: current_user))
      redirect_to article_path(@article)
    else
      render :edit
    end
  end

  private

  def set_article
    @article = Article.find params[:id]
  end

  def article_params
    params.require(:article).permit(:body_markdown, :title, :tags_cache)
  end
end
