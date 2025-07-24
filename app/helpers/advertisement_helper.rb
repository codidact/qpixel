module AdvertisementHelper
  # Character ordinal for the start of the Unicode RTL characters block.
  RTL_BLOCK_START = 0x0590
  # Character ordinal for the end of the Unicode RTL characters block.
  RTL_BLOCK_END = 0x06FF

  # Used to artificially fix RTL text in environments that are incapable of rendering mixed LTR and RTL text.
  # Parses the given string in sections of LTR and RTL; at each boundary between sections, dumps the section
  # into an output buffer - forwards if the section was LTR, reversed if the section was RTL - and clears the
  # scan buffer. This has the effect of reversing RTL sections in-place, which seems to correct their direction.
  # @param str [String] The mixed-text string on which to do witchcraft.
  # @return [String] A "fixed" string suitable to render in RTL-ignorant environments. ImageMagick, for instance.
  def do_rtl_witchcraft(str)
    chars = str.chars
    output_buffer = ''
    scan_buffer = []
    current_mode = rtl?(chars[0]) ? :rtl : :ltr
    chars.each.with_index do |c, i|
      new_mode = if c.match?(/\s/)
                   if chars[i - 1].present? && chars[i + 1].present? && rtl?(chars[i - 1]) && rtl?(chars[i + 1])
                     :rtl
                   else
                     :ltr
                   end
                 else
                   rtl?(c) ? :rtl : :ltr
                 end
      next if new_mode.nil?

      if new_mode != current_mode
        output_buffer += if current_mode == :rtl
                           scan_buffer.join.reverse
                         else
                           scan_buffer.join
                         end
        scan_buffer = []
      end
      current_mode = new_mode
      scan_buffer << c
    end

    output_buffer += if current_mode == :rtl
                       scan_buffer.join.reverse
                     else
                       scan_buffer.join
                     end
  end

  ##
  # Returns true if the provided character is part of an RTL character set.
  # @param char [String] A single-character string.
  # @return [Boolean]
  # @raise [ArgumentError] If the string provided is longer than one character.
  def rtl?(char)
    return false if char.nil?
    raise ArgumentError, 'More than one character provided' if char.length > 1

    char.ord.between?(RTL_BLOCK_START, RTL_BLOCK_END)
  end

  ##
  # Estimates the width of text for rendering in ImageMagick and attempts to wrap it over multiple lines to avoid text
  # being cut off or too short.
  # @param text [String] The text to wrap.
  # @param width [Integer] The available width in pixels.
  # @param font_size [Integer] The font size in which the text will be rendered.
  # @return [String] The wrapped text, as one string with line breaks in the right places.
  def wrap_text(text, width, font_size)
    columns = (width * 2.5 / font_size).to_i
    # Source: http://viseztrance.com/2011/03/texts-over-multiple-lines-with-rmagick.html
    text.split("\n").collect do |line|
      line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end

  ##
  # Loads and returns a Magick image either from local files or from a URI for use in generating composite Magick
  # images.
  # @param icon_path [String] A path or URI from which to load the image. If using a path this should be the asset path
  #   as it would be accessible through the Rails server - see example.
  # @return [Magick::ImageList] An ImageList containing the icon.
  # @example Load an image from app/assets/images:
  #   # This uses the path from which the image would be accessed via HTTP.
  #   helpers.community_icon('/assets/codidact.png')
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
end
