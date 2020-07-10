module AdvertisementHelper
  RTL_BLOCK_START = 0x0590
  RTL_BLOCK_END = 0x06FF

  def do_rtl_witchcraft(str)
    chars = str.chars
    final = ''
    current = []
    current_mode = rtl?(chars[0]) ? :rtl : :ltr
    chars.each.with_index do |c, i|
      new_mode = rtl?(c) ? :rtl : :ltr
      # new_mode = if c.match(/(?:\s|[[:punct:]])/)
      #              if i == chars.size - 1
      #                :ltr
      #              elsif current.size >= 1
      #                puts "[#{current_mode}] pchar #{c}    previous #{rtl?(current[-1])}    => #{rtl?(current[-1]) ? :rtl : :ltr}"
      #                rtl?(current[-1]) ? :rtl : :ltr
      #              else
      #                puts "[#{current_mode}] pchar #{c}    no previous    => ltr"
      #                :ltr
      #              end
      #            else
      #              puts "[#{current_mode}] char #{c}    => #{rtl?(c) ? :rtl : :ltr}"
      #              rtl?(c) ? :rtl : :ltr
      #            end
      if new_mode != current_mode
        if current_mode == :rtl
          final += current.join('').reverse
          puts "dump current -> reverse -> final, final = #{final}"
        else
          final += current.join('')
          puts "dump current -> final, final = #{final}"
        end
        current = []
      end
      current_mode = new_mode
      current << c
    end

    if current_mode == :rtl
      final += current.join('').reverse
    else
      final += current.join('')
    end

    final
  end

  def rtl?(c)
    return false if c.nil?

    c.ord >= RTL_BLOCK_START && c.ord <= RTL_BLOCK_END
  end
end
