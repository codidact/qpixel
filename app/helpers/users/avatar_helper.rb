require 'rmagick'

module Users::AvatarHelper
  include Magick

  def user_auto_avatar(size, user: nil, letter: nil, color: nil)
    raise ArgumentError, 'Either user or letter must be set' if user.nil? && letter.nil?
    raise ArgumentError, 'Color must be set if user is not provided' if user.nil? && color.nil?

    if letter.nil?
      letter = user.username[0]
    end
    if color.nil?
      color = "##{Digest::MD5.hexdigest(user.username)[0...6]}FF"
    end

    cache_key = if user.present?
                  "network/avatars/#{user.id}/#{size}px"
                else
                  "network/avatars/#{letter}+#{color}/#{size}px"
                end

    Rails.cache.fetch cache_key, include_community: false, expires_in: 24.hours do
      ava = Image.new(size, size)
      text_color = yiq_contrast(color, 'black', 'white')

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
      letter.annotate ava, size, size * 1.16, 0, 0, letter.upcase do
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
