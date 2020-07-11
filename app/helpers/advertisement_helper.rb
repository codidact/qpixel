module AdvertisementHelper
  RTL_BLOCK_START = 0x0590
  RTL_BLOCK_END = 0x06FF

  def do_rtl_witchcraft(str)
    chars = str.chars
    final = ''
    current = []
    current_mode = rtl?(chars[0]) ? :rtl : :ltr
    chars.each do |c|
      new_mode = rtl?(c) ? :rtl : :ltr
      if new_mode != current_mode
        final += if current_mode == :rtl
                   current.join('').reverse
                 else
                   current.join('')
                 end
        current = []
      end
      current_mode = new_mode
      current << c
    end

    final += if current_mode == :rtl
               current.join('').reverse
             else
               current.join('')
             end

    final
  end

  def rtl?(char)
    return false if char.nil?

    char.ord >= RTL_BLOCK_START && char.ord <= RTL_BLOCK_END
  end
end
