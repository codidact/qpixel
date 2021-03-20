require 'rmagick'

module Advertisements::CodidactHelper
  include Magick

  # rubocop:disable Metrics/BlockLength
  def codidact_ad
    Rails.cache.fetch 'network/codidact_ad', expires_in: 60.minutes, include_community: false do
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

      icon = ::Magick::ImageList.new('./app/assets/images/codidact.png')
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
  end
  # rubocop:enable Metrics/BlockLength
end
