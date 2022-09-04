class SearchController < ApplicationController
  def search
    @posts = if params[:search].present?
               search_data = helpers.parse_search(params[:search])
               posts = (current_user&.is_moderator || current_user&.is_admin ? Post : Post.undeleted)
                       .qa_only
               posts = helpers.qualifiers_to_sql(search_data[:qualifiers], posts)

               if search_data[:search].present?
                 search_score_key = SiteSetting['ElasticsearchEnabled'] ? :es_search_score : :search_score
                 posts = posts.search(search_data[:search])
                              .user_sort({ term: params[:sort], default: search_score_key },
                                         relevance: search_score_key, score: :score, age: :created_at)
               else
                 posts = posts.user_sort({ term: params[:sort], default: :score },
                                         score: :score, age: :created_at)
               end

               posts.list_includes.paginate(page: params[:page], per_page: 25)
             end
    @count = begin
      @posts&.count
    rescue
      @posts = nil
      flash[:danger] = 'Your search syntax is incorrect.'
    end
  end
end
