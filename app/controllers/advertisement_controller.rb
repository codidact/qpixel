require 'rmagick'
require 'open-uri'

# Necessary due to rmagick
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/BlockLength
# noinspection RubyResolve, DuplicatedCode, RubyArgCount
class AdvertisementController < ApplicationController
  include Magick

  def index
    render layout: 'without_sidebar'
  end

  def codidact
    ad = Rails.cache.fetch 'codidact_ad', expires_in: 60.minutes do
      ad = Image.new(600, 500)
      ad.background_color = 'white'

      lower_bar = Draw.new
      lower_bar.fill '#4B68FF'
      lower_bar.rectangle 0, 450, 600, 500
      lower_bar.draw ad

      community_url = Draw.new
      community_url.font_family = 'Roboto'
      community_url.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      community_url.font_weight = 700
      community_url.pointsize = 20
      community_url.gravity = CenterGravity
      community_url.annotate ad, 600, 50, 0, 450, 'Try on codidact.com' do
        self.fill = 'white'
      end

      icon = Magick::ImageList.new('./app/assets/images/codidact.png')
      icon.resize_to_fit!(500, 300)
      ad.composite!(icon, CenterGravity, 0, -125, SrcAtopCompositeOp)

      on_codidact = Draw.new
      on_codidact.font_family = 'Roboto'
      on_codidact.font_weight = 700
      on_codidact.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      on_codidact.pointsize = 25
      on_codidact.gravity = CenterGravity
      on_codidact.annotate ad, 400, 50, 100, 200, 'The Open Source Q&A Platform.' do
        self.fill = '#666666'
      end

      slogan = Draw.new
      slogan.font_family = 'Roboto'
      slogan.font_weight = 400
      slogan.font = './app/assets/imgfonts/Roboto-Regular.ttf'
      slogan.pointsize = 30
      slogan.gravity = NorthGravity
      position = 0
      wrap_text('Join our communities or build your own on codidact.com.', 500, 30).split("\n").each do |line|
        slogan.annotate ad, 500, 100, 50, 300 + position * 45, line do
          self.fill = '#333333'
        end
        position += 1
      end

      ad.format = 'PNG'
      ad.border!(2, 2, 'black')
      ad
    end
    send_data ad.to_blob, type: 'image/png', disposition: 'inline'
  end

  def community
    ad = Rails.cache.fetch "#{RequestContext.community_id}/community_ad", expires_in: 60.minutes do
      ad = Image.new(600, 500)
      ad.background_color = 'white'

      lower_bar = Draw.new
      lower_bar.fill '#4B68FF'
      lower_bar.rectangle 0, 450, 600, 500
      lower_bar.draw ad

      community_url = Draw.new
      community_url.font_family = 'Roboto'
      community_url.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      community_url.font_weight = 700
      community_url.pointsize = 20
      community_url.gravity = CenterGravity
      community_url.annotate ad, 600, 50, 0, 450, @community.host do
        self.fill = 'white'
      end

      icon_path = SiteSetting['SiteLogoPath']
      if icon_path.present?
        icon = community_icon(icon_path)
        icon.resize_to_fit!(400, 200)
        ad.composite!(icon, CenterGravity, 0, -175, SrcAtopCompositeOp)
      else
        name = @community.name
        community_name = Draw.new
        community_name.font_family = 'Roboto'
        community_name.font_weight = 900
        community_name.font = './app/assets/imgfonts/Roboto-Black.ttf'
        community_name.pointsize = (50 + (100.0 / name.length))
        community_name.gravity = CenterGravity
        community_name.annotate ad, 600, 250, 0, 0, name do
          self.fill = 'black'
        end
      end

      on_codidact = Draw.new
      on_codidact.font_family = 'Roboto'
      on_codidact.font_weight = 700
      on_codidact.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      on_codidact.pointsize = 25
      on_codidact.gravity = EastGravity
      on_codidact.annotate ad, 0, 50, 500, 150, 'on codidact.com' do
        self.fill = '#666666'
      end

      slogan = Draw.new
      slogan.font_family = 'Roboto'
      slogan.font_weight = 400
      slogan.font = './app/assets/imgfonts/Roboto-Regular.ttf'
      slogan.pointsize = 30
      slogan.gravity = NorthGravity
      position = 0
      wrap_text(SiteSetting['SiteAdSlogan'], 500, 30).split("\n").each do |line|
        slogan.annotate ad, 500, 100, 50, 225 + position * 45, line do
          self.fill = '#333333'
        end
        position += 1
      end

      ad.format = 'PNG'
      ad.border!(2, 2, 'black')
      ad
    end
    send_data ad.to_blob, type: 'image/png', disposition: 'inline'
  end

  def specific_question
    @post = Post.find(params[:id])
    if @post.question?
      question_ad(@post)
    elsif @post.article?
      article_ad(@post)
    else
      not_found
    end
  end

  def specific_category
    @category = Category.find(params[:id])
    @post = Rails.cache.fetch "community/#{RequestContext.community_id}/ca_random_category_post/#{params[:id]}",
                              expires_in: 5.minutes do
      select_random_post(@category)
    end
    if @post.question?
      question_ad(@post)
    elsif @post.article?
      article_ad(@post)
    else
      not_found
    end
  end

  def random_question
    @post = Rails.cache.fetch "community/#{RequestContext.community_id}/ca_random_hot_post", expires_in: 5.minutes do
      select_random_post
    end
    if @post.nil?
      return community
    end

    if @post.question?
      question_ad(@post)
    elsif @post.article?
      article_ad(@post)
    else
      not_found
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
    Post.undeleted.where(last_activity: (Rails.env.development? ? 365 : 7).days.ago..Time.now)
        .where(post_type_id: Question.post_type_id)
        .where(category: category)
        .where('score > ?', SiteSetting['HotPostsScoreThreshold'])
        .order('score DESC').limit(SiteSetting['HotQuestionsCount']).all.sample
  end

  def wrap_text(text, width, font_size)
    columns = (width * 2.0 / font_size).to_i
    # Source: http://viseztrance.com/2011/03/texts-over-multiple-lines-with-rmagick.html
    text.split("\n").collect do |line|
      line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end

  def question_ad(question)
    ad = Rails.cache.fetch "posts/#{question.id}/ad", expires_in: 60.minutes do
      ad = Image.new(600, 500)
      ad.background_color = 'white'

      upper_bar = Draw.new
      upper_bar.fill '#4B68FF'
      upper_bar.rectangle 0, 0, 600, 130
      upper_bar.draw ad

      answer = Draw.new
      answer.font_family = 'Roboto'
      answer.font_weight = 700
      answer.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      answer.pointsize = 40
      answer.gravity = CenterGravity
      answer.annotate ad, 600, 50, 0, 10, 'Could you answer' do
        self.fill = 'white'
      end
      answer.annotate ad, 600, 50, 0, 70, 'this question?' do
        self.fill = 'white'
      end

      icon_path = SiteSetting['SiteLogoPath']
      if icon_path.present?
        icon = community_icon(icon_path)
        icon.resize_to_fit!(175, 75)
        ad.composite!(icon, SouthWestGravity, 20, 15, SrcAtopCompositeOp)
      else
        community_name = Draw.new
        community_name.font_family = 'Roboto'
        community_name.font_weight = 700
        community_name.font = './app/assets/imgfonts/Roboto-Bold.ttf'
        community_name.pointsize = 25
        community_name.gravity = SouthWestGravity
        community_name.annotate ad, 0, 0, 20, 20, question.community.name do
          self.fill = '#4B68FF'
        end
      end

      community_url = Draw.new
      community_url.font_family = 'Roboto'
      community_url.font_weight = 700
      community_url.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      community_url.pointsize = 20
      community_url.gravity = SouthEastGravity
      community_url.annotate ad, 0, 0, 20, 20, question.community.host do
        self.fill = '#666666'
      end

      title = Draw.new
      title.font_family = 'Roboto'
      title.font_weight = 900
      title.font = './app/assets/imgfonts/Roboto-Black-FRLHebrew.ttf'
      title.pointsize = 50
      title.gravity = NorthGravity
      position = 0
      if question.title.length > 60
        title.pointsize = 35
        wrap_text(helpers.do_rtl_witchcraft(question.title), 500, 35).split("\n").each do |line|
          title.annotate ad, 500, 100, 50, 135 + position * 55, line do
            self.fill = '#333333'
          end
          position += 1
        end
      else
        wrap_text(helpers.do_rtl_witchcraft(question.title), 500, 55).split("\n").each do |line|
          title.annotate ad, 500, 100, 50, 160 + position * 70, line do
            self.fill = '#333333'
          end
          position += 1
        end
      end

      ad.format = 'PNG'
      ad.border!(2, 2, 'black')
    end
    send_data ad.to_blob, type: 'image/png', disposition: 'inline'
  end

  def article_ad(article)
    ad = Rails.cache.fetch "posts/#{article.id}/ad", expires_in: 60.minutes do
      ad = Image.new(600, 500)
      ad.background_color = 'white'

      upper_bar = Draw.new
      upper_bar.fill '#4B68FF'
      upper_bar.rectangle 0, 0, 600, 130
      upper_bar.draw ad

      answer = Draw.new
      answer.font_family = 'Roboto'
      answer.font_weight = 700
      answer.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      answer.pointsize = 40
      answer.gravity = CenterGravity
      answer.annotate ad, 600, 120, 0, 10, 'Check out this article' do
        self.fill = 'white'
      end

      icon_path = SiteSetting['SiteLogoPath']
      if icon_path.present?
        icon = community_icon(icon_path)
        icon.resize_to_fit!(120, 50)
        ad.composite!(icon, SouthWestGravity, 20, 15, SrcAtopCompositeOp)
      else
        community_name = Draw.new
        community_name.font_family = 'Roboto'
        community_name.font_weight = 700
        community_name.font = './app/assets/imgfonts/Roboto-Bold.ttf'
        community_name.pointsize = 25
        community_name.gravity = SouthWestGravity
        community_name.annotate ad, 0, 0, 20, 20, article.community.name do
          self.fill = '#4B68FF'
        end
      end

      community_url = Draw.new
      community_url.font_family = 'Roboto'
      community_url.font_weight = 700
      community_url.font = './app/assets/imgfonts/Roboto-Bold.ttf'
      community_url.pointsize = 20
      community_url.gravity = SouthEastGravity
      community_url.annotate ad, 0, 0, 20, 20, article.community.host do
        self.fill = '#666666'
      end

      title = Draw.new
      title.font_family = 'Roboto'
      title.font_weight = 900
      title.font = './app/assets/imgfonts/Roboto-Black-FRLHebrew.ttf'
      title.pointsize = 50
      title.gravity = NorthGravity
      position = 0
      if article.title.length > 60
        title.pointsize = 35
        wrap_text(helpers.do_rtl_witchcraft(article.title), 500, 35).split("\n").each do |line|
          title.annotate ad, 500, 100, 50, 135 + position * 55, line do
            self.fill = '#333333'
          end
          position += 1
        end
      else
        wrap_text(helpers.do_rtl_witchcraft(article.title), 500, 55).split("\n").each do |line|
          title.annotate ad, 500, 100, 50, 160 + position * 70, line do
            self.fill = '#333333'
          end
          position += 1
        end
      end

      ad.format = 'PNG'
      ad.border!(2, 2, 'black')
    end
    send_data ad.to_blob, type: 'image/png', disposition: 'inline'
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
