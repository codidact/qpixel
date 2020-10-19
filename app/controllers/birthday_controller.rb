class BirthdayController < ApplicationController
  def index
    render layout: 'without_sidebar'
  end

  def ranking
    @ranking = Rails.cache.fetch('birthday-ranking', expires_in: 1.hour) do
      User.unscoped.joins('INNER JOIN posts ON posts.user_id = users.id').where('posts.score > 0.6') \
          .where('posts.created_at >= \'2020-10-16\' AND posts.created_at <= \'2020-10-23\'') \
          .where(staff: false).group('posts.user_id').select('users.*', 'count(posts.id) as post_count') \
          .order('post_count DESC, users.created_at DESC').all
    end
    render layout: 'without_sidebar'
  end
end
