require 'rmagick'

module Advertisements::ArticleHelper
  include Magick

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/BlockLength
  def article_ad(article)
    Rails.cache.fetch "posts/#{article.id}/ad", expires_in: 60.minutes do
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

      icon_path = SiteSetting.find_by(name: 'SiteLogoPath', community: article.community).typed
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
        wrap_text(do_rtl_witchcraft(article.title), 500, 35).split("\n").each do |line|
          title.annotate ad, 500, 100, 50, 135 + position * 55, line do
            self.fill = '#333333'
          end
          position += 1
        end
      else
        wrap_text(do_rtl_witchcraft(article.title), 500, 55).split("\n").each do |line|
          title.annotate ad, 500, 100, 50, 160 + position * 70, line do
            self.fill = '#333333'
          end
          position += 1
        end
      end

      ad.format = 'PNG'
      ad.border!(2, 2, 'black')
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/BlockLength
end
