# Provides helper methods for use by views under <tt>ModeratorController</tt>.
module ModeratorHelper
  ##
  # Display text on a specified background color.
  # @param cls [String] The background color class.
  # @param content [String] The text to display. For uses beyond simple text, pass a block instead.
  # @option opts :class [String] Additional classes to add to the element.
  # For instance, if the background color is dark, consider passing a class for a light text color.
  # @yieldparam context [ActionView::Helpers::TagHelper::TagBuilder]
  # @yieldreturn [ActiveSupport::SafeBuffer, String]
  # @return [ActiveSupport::SafeBuffer]
  def text_bg(cls, content = nil, **opts, &block)
    if block_given?
      tag.span class: ["has-background-color-#{cls}", opts[:class]].join(' '), &block
    else
      tag.span content, class: ["has-background-color-#{cls}", opts[:class]].join(' ')
    end
  end

  ##
  # Split an IP address into an array of hashed octets (well, hexadecets for IPv6).
  # @param ip [String] The IP address to process.
  # @param salting_user [User] A user from which to source a salt for hashing. For hashes to be directly comparable, you
  # must use the same user for each IP address you wish to compare, even if sourced from a different user.
  # @return [[String, [String?]]] The IP address family, and an array of hashed octets.
  def split_hash_ip(ip, salting_user)
    begin
      addr = IPAddress.parse(ip)
    rescue ArgumentError
      return ['', []]
    end
    splat = if addr.ipv6?
              addr.hexs
            else
              addr.octets
            end
    salt = BCrypt::Password.new(salting_user.encrypted_password).salt
    splat = splat.map { |p| Digest::SHA2.hexdigest(salt + p.to_s) }
    [
      addr.ipv6? ? 'IPv6' : 'IPv4',
      splat
    ]
  end
end
