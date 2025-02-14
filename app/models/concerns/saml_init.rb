# Module for saml based initalization.
#
# The saml_init_email method is used to initialize the email address after a successful SSO sign in.
# The saml_init_identifier method is used to
module SamlInit
  extend ActiveSupport::Concern

  included do
    has_one :sso_profile, required: false, autosave: true, dependent: :destroy

    before_validation :prepare_from_saml, if: -> { saml_identifier.present? }
  end

  # -----------------------------------------------------------------------------------------------
  # Identifier
  # -----------------------------------------------------------------------------------------------

  # @return [String, Nil] the saml_identifier of this user, or nil if the user is not from SSO
  def saml_identifier
    sso_profile&.saml_identifier
  end

  # @param saml_identifier [String, Nil] sets (or clears) the saml_identifier of this user
  def saml_identifier=(saml_identifier)
    if saml_identifier.nil?
      sso_profile&.destroy
    else
      build_sso_profile if sso_profile.nil?
      sso_profile.saml_identifier = saml_identifier
    end
  end

  # This method is added as a fallback to support the Single Logout Service.
  #
  # @return [String, Nil] the saml_identifier of this user, or nil if the user is not from SSO
  # @see #saml_identifier
  def saml_init_identifier
    saml_identifier
  end

  # Sets the saml_identifier to the given saml_identifier upon initialization. In contrast to
  # #saml_identifier=, this method does not delete the SSO profile in case the saml_identifier is
  # not present (safety in case of SSO issues).
  #
  # @param saml_identifier [String, Nil] the saml_identifier
  # @return [String, Nil] the saml_identifier of this user, should never be nil
  def saml_init_identifier=(saml_identifier)
    build_sso_profile if sso_profile.nil?

    # Only update if non-empty
    sso_profile.saml_identifier = saml_identifier if saml_identifier.present?
  end

  # -----------------------------------------------------------------------------------------------
  # Email
  # -----------------------------------------------------------------------------------------------

  # This method is added as a fallback to support the Single Logout Service.
  # @return [String, Nil] the email address of this user, or nil if the user is not from SSO
  def saml_init_email
    return nil if sso_profile.nil?

    email
  end

  # Initializes email address, and prevents (re)confirmation in case it is changed.
  #
  # @param email [String] the email address
  def saml_init_email=(email)
    self.email = email
    skip_confirmation!
    skip_reconfirmation!
  end

  # -----------------------------------------------------------------------------------------------
  # Email is identifier
  # -----------------------------------------------------------------------------------------------

  # Used in the case that email is the unique identifier from saml.
  # @return [String, Nil] the email address of the user, or nil in the case the user is not from SSO
  def saml_init_email_and_identifier
    return nil if sso_profile.nil?

    email
  end

  # Used in the case that email is the unique identifier from saml.
  #
  # @param email [String] the email address (and saml identifier)
  def saml_init_email_and_identifier=(email)
    self.saml_init_email = email
    self.saml_init_identifier = email
  end

  # -----------------------------------------------------------------------------------------------
  # Username
  # -----------------------------------------------------------------------------------------------

  # This method is added as fallback to support the Single Logout Service.
  # @return [String] the username
  def saml_init_username_no_update
    username
  end

  # Sets the username from SAML in case it was not already set.
  # This prevents overriding the user set username with the one from SAML all the time, while
  # allowing for email updates to be applied.
  #
  # @param username [String] the username to set
  def saml_init_username_no_update=(username)
    self.username = username unless self.username.present?
  end

  # -----------------------------------------------------------------------------------------------
  # Creation
  # -----------------------------------------------------------------------------------------------

  protected

  # Prepare a (potentially) new user from saml for creation. If the user is actually new, a random
  # password is created for them and email confirmation is skipped.
  def prepare_from_saml
    return unless new_record?

    self.password = SecureRandom.hex
    skip_confirmation!
  end
end
