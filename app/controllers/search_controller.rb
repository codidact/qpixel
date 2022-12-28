class SearchController < ApplicationController
  def search
    @posts = helpers.search_posts
    @active_filter = helpers.active_filter
    @count = begin
      @posts&.count
    rescue
      @posts = nil
      flash[:danger] = 'Your search syntax is incorrect.'
    end
  end
end
