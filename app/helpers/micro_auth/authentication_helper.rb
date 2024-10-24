module MicroAuth::AuthenticationHelper
  ##
  # Contains all valid scopes for authentication requests. A `nil` description indicates a scope that is not displayed
  # to the user during authentication requests.
  # @return [Hash{String => String}] A hash of valid authentication scopes.
  def valid_auth_scopes
    {
      'perpetual' => nil,
      'pii' => 'Access to personal information (including email address)'
    }
  end

  ##
  # Builds a redirect URI, adding specified parameters as necessary.
  # @param redirect_uri [String] The base redirect URI to start from
  # @param params [Hash{Symbol => #to_s}] A hash of parameters to add as query parameters to the URI
  # @return [String] The final URI.
  def construct_redirect(redirect_uri, **params)
    uri = URI(redirect_uri)
    query = URI.decode_www_form(uri.query || '').to_h.merge(params)
    uri.query = URI.encode_www_form(query.to_a)
    uri.to_s
  end

  ##
  # Provides a hash of user data based on what data the provided token is scoped to access. For instance, +:email+ will
  # only be included when a +pii+ scoped token is presented.
  # @param token [MicroAuth::Token] A Token instance to specify the scoped access level.
  # @return [Hash{Symbol => Object}] A user data hash.
  def authenticated_user_object(token)
    fields = [:id, :created_at, :is_global_moderator, :is_global_admin, :username, :website, :twitter, :staff,
              :developer, :discord]
    fields << :email if token.scope.include? 'pii'
    fields.to_h { |f| [f, token.user.send(f)] }
  end
end
