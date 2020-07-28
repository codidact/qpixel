# Web controller. Provides authenticated actions for use by moderators. A lot of the stuff in here, and hence a lot of
# the tools, are rather repetitive.
class ModeratorController < ApplicationController
  before_action :verify_moderator

  def index; end

  def recently_deleted_posts
    @posts = Post.unscoped.where(community: @community, deleted: true).order('deleted_at DESC')
                 .paginate(page: params[:page], per_page: 50)
  end
end
