require 'rmagick'

module Users::AvatarHelper
  include Magick

  def user_auto_avatar(user, size)
    Rails.cache.fetch "network/avatars/#{user.id}/#{size}px", include_community: false, expires_in: 24.hours do
      ava = Image.new(size, size)
      background = "##{Digest::MD5.hexdigest(user.username)[0...6]}FF"
      text_color = yiq_contrast(background, 'black', 'white')

      bg = Draw.new
      bg.fill background
      bg.rectangle 0, 0, size, size
      bg.draw ava

      letter = Draw.new
      letter.font_family = 'Roboto'
      letter.font_weight = 400
      letter.font = './app/assets/imgfonts/Roboto.ttf'
      letter.pointsize = size * 0.75
      letter.gravity = CenterGravity
      letter.annotate ava, size, size * 1.16, 0, 0, user.username[0].upcase do
        self.fill = text_color
      end

      ava.format = 'PNG'
      ava
    end
  end

  # Returns on_light if the given base color is light, and vice versa.
  # Useful for picking a text color to use on a dynamic background.
  def yiq_contrast(base, on_light, on_dark)
    base = base[1..]
    red = base[0...2].to_i(16)
    green = base[2...4].to_i(16)
    blue = base[4...6].to_i(16)
    yiq = ((red * 299) + (green * 587) + (blue * 114)) / 1000
    yiq >= 128 ? on_light : on_dark
  end
end
