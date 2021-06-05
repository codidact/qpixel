module AdvertisementHelper
  RTL_BLOCK_START = 0x0590
  RTL_BLOCK_END = 0x06FF

  # Used to artificially fix RTL text in environments that are incapable of rendering mixed LTR and RTL text.
  # Parses the given string in sections of LTR and RTL; at each boundary between sections, dumps the section
  # into an output buffer - forwards if the section was LTR, reversed if the section was RTL - and clears the
  # scan buffer. This has the effect of reversing RTL sections in-place, which seems to correct their direction.
  #
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

  def rtl?(char)
    return false if char.nil?

    char.ord >= RTL_BLOCK_START && char.ord <= RTL_BLOCK_END
  end

  def wrap_text(text, width, font_size)
    columns = (width * 2.5 / font_size).to_i
    # Source: http://viseztrance.com/2011/03/texts-over-multiple-lines-with-rmagick.html
    text.split("\n").collect do |line|
      line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end

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
