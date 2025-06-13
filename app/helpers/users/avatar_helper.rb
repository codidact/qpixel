require 'rmagick'

module Users::AvatarHelper
  include Magick

  ##
  # Creates an avatar image based either on a user account or on provided values.
  # @overload user_auto_avatar(size, user: nil)
  #   @param size [Integer] The side length of the final image, in pixels. O(n^2) at minimum - large values will take
  #     exponentially longer to generate.
  #   @param user [User] A user object from which to take the avatar letter and color
  # @overload user_auto_avatar(size, letter: nil, color: nil)
  #   @param size [Integer] The side length of the final image, in pixels. O(n^2) at minimum - large values will take
  #     exponentially longer to generate.
  #   @param letter [String] A single character to display on the avatar if +user+ is not set
  #   @param color [String] An 8-digit hex code, with leading +#+, to color the avatar background if +user+ is not set
  # @return [Magick::Image] The generated avatar
  # @raise [ArgumentError] If a user or letter-color combination is not provided.
  # @example Generate an avatar for the current user:
  #   helpers.user_auto_avatar(64, user: current_user)
  # @example Generate a generic avatar:
  #   helpers.user_auto_avatar(32, letter: 'A', color: '#3C0FFEE5')
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
      bg.fill color
      bg.rectangle 0, 0, size, size
      bg.draw ava

      let = Draw.new
      let.font_family = 'Roboto'
      let.font_weight = 400
      let.font = './app/assets/imgfonts/Roboto.ttf'
      let.pointsize = size * 0.75
      let.gravity = CenterGravity
      let.annotate ava, size, size * 1.16, 0, 0, letter.upcase do |s|
        s.fill = text_color
      end

      ava.format = 'PNG'
      ava
    end
  end

  ##
  # Returns on_light if the given base color is light, and vice versa. Useful for picking a text color to use on a
  # dynamic background. Uses the YIQ color space.
  # @param base [String] The base/background color on which to base the calculation.
  # @param on_light [String] The text color to use on a light background.
  # @param on_dark [String] The text color to use on a dark background.
  # @return [String] The text color to use, either +on_light+ or +on_dark+.
  def yiq_contrast(base, on_light, on_dark)
    base = base[1..]
    red = base[0...2].to_i(16)
    green = base[2...4].to_i(16)
    blue = base[4...6].to_i(16)
    yiq = ((red * 299) + (green * 587) + (blue * 114)) / 1000
    yiq >= 128 ? on_light : on_dark
  end
end
