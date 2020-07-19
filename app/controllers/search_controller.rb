class SearchController < ApplicationController
  before_action :stop_the_awful_troll
  
  def search
    @posts = if params[:search].present?
               search_data = helpers.parse_search(params[:search])
               posts = (current_user&.is_moderator || current_user&.is_admin ? Post : Post.undeleted)
                       .qa_only.where(helpers.qualifiers_to_sql(search_data[:qualifiers]))
                       .includes(:user, user: :avatar_attachment)
                       .paginate(page: params[:page], per_page: 25)

               if search_data[:search].present?
                 posts.search(search_data[:search]).user_sort({ term: params[:search], default: :search_score },
                                                              relevance: :search_score, score: :score, age: :created_at)
               else
                 posts.user_sort({ term: params[:search], default: :score },
                                 score: :score, age: :created_at)
               end
             end
    @count = begin
               @posts&.count
             rescue
               @posts = nil
               flash[:danger] = 'Your search syntax is incorrect.'
             end
  end
end
