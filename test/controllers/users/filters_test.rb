require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'delete_filter should correctly handle deletion' do
    sign_in users(:standard_user)

    try_delete_filter
    assert_json_failure(:bad_request)

    try_delete_filter(name: 'non-existent')
    assert_json_failure(:not_found)

    try_delete_filter(name: filters(:one).name)
    assert_json_success
  end

  test 'only global admins should be able to delete system filters' do
    filter = filters(:system)

    users.each do |user|
      sign_in user

      name = "system_#{user.name}"
      Filter.create!(filter.dup.attributes.merge({ name: name,
                                                   user: User.system }))

      try_delete_filter(name: name, system: true)

      if user.global_admin?
        assert_json_success
      else
        assert_json_failure(:bad_request)
      end
    end
  end

  test 'set_filter should correctly save valid filters' do
    sign_in users(:standard_user)

    [false, true].each do |is_default|
      try_save_filter(is_default: is_default)
      assert_json_success
    end
  end

  test 'default_filter should correctly respond to missing category' do
    sign_in users(:standard_user)
    try_default_filter(nil)
    assert_response(:bad_request)
  end

  test 'default_filter should correctly get default category filters' do
    sign_in users(:standard_user)
    try_default_filter(categories(:main))
    assert_json_success
  end

  test 'HTML filters should redirect to sign in for anonymous users' do
    try_filters(format: :html)
    assert_redirected_to_sign_in
  end

  test 'JSON filters should return system filters for anonymous users' do
    try_filters(format: :json)

    assert_response(:success)
    assert_valid_json_response

    parsed = JSON.parse(response.body)
    assert parsed.any?
    parsed.each do |name, filter|
      assert filter['system'], "'#{name}' is not a system filter"
    end
  end

  private

  def try_filters(format: :json)
    get :filters, params: { format: format }
  end

  def try_default_filter(category)
    get :default_filter, params: {
      category: category&.id,
      format: :json
    }
  end

  def try_delete_filter(**opts)
    delete :delete_filter, params: {
      name: '',
      system: false
    }.merge(opts)
  end

  def try_save_filter(**opts)
    filter = { name: 'test filter' }.merge(opts)
    post :set_filter, params: filter.merge({ format: :json })
  end
end
