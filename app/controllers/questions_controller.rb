# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  def lottery
    ids = Rails.cache.fetch 'lottery_questions', expires_in: 24.hours do
      # noinspection RailsParamDefResolve
      Post.main.undeleted..where(post_type: top_level_post_types)
        .order([Arel.sql('(RAND() - ? * DATEDIFF(CURRENT_TIMESTAMP, posts.created_at)) DESC'),
                SiteSetting['LotteryAgeDeprecationSpeed']])
        .limit(25).select(:id).pluck(:id).to_a
    end
    @questions = Question.list_includes.where(id: ids).paginate(page: params[:page], per_page: 25)
  end
end
