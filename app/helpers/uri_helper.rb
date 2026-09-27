module UriHelper
  [:http, :https].each do |method|
    # Does a given URI have the relevant scheme?
    # @param uri [String] URI to check
    # @return [Boolean] check result
    define_method "#{method}_uri?" do |uri|
      URI(uri).scheme.casecmp(method.to_s).zero?
    end
  end

  # Forces a given URI to be a safe one
  # @para uri [String] URI to fixup
  # @param scheme [Symbol] scheme to use if the URI is unsafe
  # @return [String] safe URI
  def force_safe_uri(uri, scheme = :http)
    return uri if safe_uri?(uri)

    safe_uri?(uri) ? uri : "#{scheme}://#{uri}"
  end

  # Is a given URI a relative one?
  # @param uri [String] URI to check
  # @return [Boolean] check result
  def relative_uri?(uri)
    URI(uri).relative?
  end

  # Is a given URI a safe one (absolute http://, https://, or relative)?
  # @param uri [String] URI to check
  # @return [Boolean] check result
  def safe_uri?(uri)
    relative_uri?(uri) || http_uri?(uri) || https_uri?(uri)
  end
end
