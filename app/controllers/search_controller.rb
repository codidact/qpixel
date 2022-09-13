class SearchController < ApplicationController
  def search
    @posts = helpers.search_posts
    @count = begin
      @posts&.count
    rescue
      @posts = nil
      flash[:danger] = 'Your search syntax is incorrect.'
    end
  end
end
