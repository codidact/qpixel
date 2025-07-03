require 'test_helper'

# This class serves as the base for all system test cases.
#
# The DRIVER environment variable is used to determine the browser that is used. Possible options are:
# - headless_chrome
# - chrome
# - headless_firefox (default)
# - firefox
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  DRIVER = if ENV['DRIVER']
             ENV['DRIVER'].to_sym
           else
             :headless_firefox
           end

  driven_by :selenium, using: DRIVER, screen_size: [1920, 1080]

  setup do
    Community.first.update(host: root_url.gsub(/https?:\/\//, '').gsub('/', ''))
  end

  # Logs in as the specified user
  #
  # @param user_or_fixture [User, Symbol] either a user or a symbol referring to a user from the fixtures
  # @param password [String] the password to sign in with
  def log_in(user_or_fixture, password = 'test123')
    @user = user(user_or_fixture)
    visit new_user_session_url
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: password

    click_button 'Sign in'
  end

  # Attempts to log out using the buttons in the top menu bar.
  def log_out
    within :css, '.header' do
      find(:css, 'i.far.fa-caret-square-down').find(:xpath, '..').click
    end

    find_link('Sign Out').click
  end

  # Pretends the user has clicked the confirmation link in the email they received.
  #
  # @param user_or_fixture [User, Symbol] the user or a symbol referring to the user fixture to use
  def confirm_email(user_or_fixture)
    u = user(user_or_fixture)
    visit user_confirmation_url(
      params: { confirmation_token: u.confirmation_token }
    )
  end

  # Translates the given parameter to a proper user.
  #
  # @param user_or_fixture [User, Symbol] either a user or a symbol referring to a fixture
  def user(user_or_fixture)
    if user_or_fixture.is_a?(User)
      user_or_fixture
    else
      users(user_or_fixture)
    end
  end

  # In the post form, this method will select the given tag.
  #
  # @param tag_name [String] the name of the tag
  # @param create_new [Boolean] whether creating a new tag is allowed (default false)
  def post_form_select_tag(tag_name, create_new = false)
    # First enter the tag name into the select2 search field for the tag
    within find_field('Tags (at least one):').find(:xpath, '..') do
      find('.select2-search__field').fill_in(with: tag_name)
    end

    # Wait for tag search to finish
    assert_text("Searching…")
    assert_no_text("Searching…")

    # Get the first and last options listed
    first_option = find('#select2-post_tags_cache-results li:first-child')
    last_option = find('#select2-post_tags_cache-results li:last-child')

    # If the first option matches the tag name, and the tag already exists, click it.
    if first_option.first('span').text == tag_name && !first_option.text.include?('Create new tag')
      first_option.click
    # If we are allowed to create a tag, select the last option from the list, which is always the tag creation.
    elsif create_new
      if last_option.first('span').text == tag_name
        last_option.click
      else
        raise "Tried to select tag #{tag_name} for creation, but it does not seem to be a presented option."
      end
    # The first option is not the tag we were looking for, and we are not allowed to create a tag.
    else
      raise "Expected to find tag with the name #{tag_name}, " \
            'but could not select it from options without creating a new tag.'
    end
  end
end
