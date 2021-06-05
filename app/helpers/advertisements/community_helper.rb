require 'rmagick'

module Advertisements::CommunityHelper
  include Magick

  # rubocop:disable Metrics/BlockLength
  def community_ad
    Rails.cache.fetch 'community_ad', expires_in: 60.minutes do
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
  end
  # rubocop:enable Metrics/BlockLength
end
