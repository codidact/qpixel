module UriHelper
  [:http, :https].each do |method|
    # Does a given URI have the relevant scheme?
    # @param {String} uri URI to check
    # @return {Boolean} check result
    define_method "#{method}_uri?" do |uri|
      URI(uri).scheme.casecmp(method.to_s).zero?
    end
  end

  # Is a given URI a relative one?
  # @param {String} uri URI to check
  # @return {Boolean} check result
  def relative_uri?(uri)
    URI(uri).relative?
  end

  # Is a given URI a safe one (absolute http://, https://, or relative)?
  # @param {String} uri URI to check
  # @return {Boolean} check result
  def safe_uri?(uri)
    relative_uri?(uri) || http_uri?(uri) || https_uri?(uri)
  end
end
