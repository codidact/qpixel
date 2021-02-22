class SearchController < ApplicationController
  def search
    @posts = if params[:search].present?
               search_data = helpers.parse_search(params[:search])
               posts = (current_user&.is_moderator || current_user&.is_admin ? Post : Post.undeleted)
                       .qa_only.list_includes
               posts = helpers.qualifiers_to_sql(search_data[:qualifiers], posts)
               posts = posts.paginate(page: params[:page], per_page: 25)

               if search_data[:search].present?
                 posts.search(search_data[:search]).user_sort({ term: params[:sort], default: :search_score },
                                                              relevance: :search_score, score: :score, age: :created_at)
               else
                 posts.user_sort({ term: params[:sort], default: :score },
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
