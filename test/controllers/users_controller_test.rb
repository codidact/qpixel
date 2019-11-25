require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should get index" do
    get :index
    assert_not_nil assigns(:users)
    assert_response(200)
  end

  test "should get show user page" do
    sign_in users(:standard_user)
    get :show, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(200)
  end

  test "should get mod tools page" do
    sign_in users(:moderator)
    get :mod, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(200)
  end

  test "should require authentication to access mod tools" do
    sign_out :user
    get :mod, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test "should require moderator status to access mod tools" do
    sign_in users(:standard_user)
    get :mod, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test "should destroy user" do
    sign_in users(:moderator)
    delete :destroy, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test "should require authentication to destroy user" do
    sign_out :user
    delete :destroy, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test "should require moderator status to destroy user" do
    sign_in users(:standard_user)
    delete :destroy, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test "soft deleting a user should not lose content" do
    sign_in users(:admin)
    assert_nothing_raised do
      needs_transfer = ApplicationRecord.connection.tables.map { |t| [t, ApplicationRecord.connection.columns(t).map(&:name)] }
                           .to_h.select { |_, cs| cs.include?('user_id') }
                           .map { |k, _| k.singularize.classify.constantize rescue nil }.compact
      pre_counts = needs_transfer.map { |model| [model, model.count] }.to_h

      id = users(:standard_user).id
      delete :soft_delete, params: { id: id, transfer: users(:editor).id }

      assert_response 200
      assert_not_nil assigns(:user)
      assert_equal 'success', JSON.parse(response.body)['status']

      # Make sure the record has actually been deleted.
      assert_raises ActiveRecord::RecordNotFound do
        User.find(id)
      end

      pre_counts.each do |model, count|
        # No content should have been lost to deleting the user, just re-assigned.
        assert_equal count, model.count
      end
    end
  end

  test "should require authentication to soft-delete user" do
    sign_out :user
    delete :soft_delete, params: { id: users(:standard_user).id, transfer: users(:editor).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test "should require admin status to soft-delete user" do
    sign_in users(:standard_user)
    delete :soft_delete, params: { id: users(:standard_user).id, transfer: users(:editor).id }
    assert_nil assigns(:user)
    assert_response(404)
  end
end
