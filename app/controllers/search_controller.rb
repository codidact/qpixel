class SearchController < ApplicationController
  def search
    @posts = if params[:search].present?
               order_params = { relevance: 'search_score DESC', score: 'score DESC', age: 'created_at DESC' }
               order = order_params.include?(params[:sort]&.to_sym) ?
                         order_params[params[:sort].to_sym] :
                         order_params[:relevance]
               Post.search(params[:search]).paginate(page: params[:page], per_page: 25).includes(:user, user: :avatar_attachment)
                   .order(Arel.sql(order))
             else
               nil
             end
  end
end