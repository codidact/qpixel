module MicroAuth::AuthenticationHelper
  # Contains all valid scopes for authentication requests.
  #
  # A `nil` description indicates a scope that is not displayed to the user during authentication
  # requests.
  def valid_auth_scopes
    {
      'perpetual' => nil,
      'pii' => 'Access to personal information (including email address)'
    }
  end

  def construct_redirect(redirect_uri, **params)
    uri = URI(redirect_uri)
    query = URI.decode_www_form(uri.query || '').to_h.merge(params)
    uri.query = URI.encode_www_form(query.to_a)
    uri.to_s
  end

  def authenticated_user_object(token)
    fields = [:id, :created_at, :is_global_moderator, :is_global_admin, :username, :website, :twitter, :staff,
              :developer, :discord]
    fields << :email if token.scope.include? 'pii'
    fields.to_h { |f| [f, token.user.send(f)] }
  end
end
