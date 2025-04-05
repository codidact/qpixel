class SearchController < ApplicationController
  def search
    @posts, @qualifiers = helpers.search_posts

    @signed_out_me = @qualifiers.any? { |q| q[:param] == :user && q[:user_id].nil? }

    @active_filter = helpers.active_filter

    @count = begin
      @posts&.count
    rescue
      @posts = nil
      flash[:danger] = 'Your search syntax is incorrect.'
    end
  end
end
