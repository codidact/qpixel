require 'rmagick'
require 'open-uri'

# Necessary due to rmagick
# noinspection RubyResolve, DuplicatedCode, RubyArgCount
class AdvertisementController < ApplicationController
  include Magick

  def index
    render layout: 'without_sidebar'
  end

  def codidact
    helpers.codidact_ad
  end

  def community
    helpers.community_ad
  end

  def specific_question
    @post = Post.unscoped.find(params[:id])

    if @post.nil?
      not_found
    elsif @post.question?
      helpers.question_ad(@post)
    elsif @post.article?
      helpers.article_ad(@post)
    else
      not_found
    end
  end

  def specific_category
    @category = Category.unscoped.find(params[:id])
    @post = Rails.cache.fetch "ca_random_category_post/#{params[:id]}",
                              expires_in: 5.minutes do
      select_random_post(@category)
    end

    if @post.nil?
      not_found
    elsif @post.question?
      helpers.question_ad(@post)
    elsif @post.article?
      helpers.article_ad(@post)
    else
      not_found
    end
  end

  def random_question
    @post = Rails.cache.fetch 'ca_random_hot_post', expires_in: 5.minutes do
      select_random_post
    end
    if @post.nil?
      return community
    end

    if @post.question?
      helpers.question_ad(@post)
    elsif @post.article?
      helpers.article_ad(@post)
    else
      not_found
    end
  end

  def promoted_post
    promoted = helpers.promoted_posts
    if promoted.empty?
      return community
    end

    @post = Post.unscoped.find(promoted.keys.sample)
    if @post.article?
      helpers.article_ad(@post)
    else
      helpers.question_ad(@post)
    end
  end

  private

  def community_icon(icon_path)
    if icon_path.start_with? '/assets/'
      icon = Magick::ImageList.new("./app/assets/images/#{File.basename(icon_path)}")
    else
      icon = Magick::ImageList.new
      icon_path_content = URI.open(icon_path).read # rubocop:disable Security/Open
      icon.from_blob(icon_path_content)
    end
    icon
  end

  def select_random_post(category = nil)
    if category.nil?
      category = Category.where(use_for_advertisement: true)
    end
    Post.undeleted.joins(:post_type).where(post_types: { is_top_level: true })\
        .where(posts: { last_activity: (Rails.env.development? ? 365 : 7).days.ago..DateTime.now })\
        .where(posts: { category: category })\
        .where('posts.score > ?', SiteSetting['HotPostsScoreThreshold'])\
        .order('posts.score DESC').limit(SiteSetting['HotQuestionsCount']).all.sample
  end
end
