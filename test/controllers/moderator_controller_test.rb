require 'test_helper'

class ModeratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should get index" do
    sign_in users(:moderator)
    get :index
    assert_response(200)
  end

  test "should get recently deleted questions" do
    sign_in users(:moderator)
    get :recently_deleted_questions
    assert_not_nil assigns(:questions)
    assigns(:questions).each do |question|
      assert_equal true, question.deleted
    end
    assert_response(200)
  end

  test "should get recently deleted answers" do
    sign_in users(:moderator)
    get :recently_deleted_answers
    assert_not_nil assigns(:answers)
    assigns(:answers).each do |answer|
      assert_equal true, answer.deleted
    end
    assert_response(200)
  end

  test "should get recently undeleted questions" do
    sign_in users(:moderator)
    get :recently_undeleted_questions
    assert_not_nil assigns(:questions)
    assigns(:questions).each do |question|
      assert_equal false, question.deleted
    end
    assert_response(200)
  end

  test "should get recently undeleted answers" do
    sign_in users(:moderator)
    get :recently_undeleted_answers
    assert_not_nil assigns(:answers)
    assigns(:answers).each do |answer|
      assert_equal false, answer.deleted
    end
    assert_response(200)
  end

  test "should require authentication to access pages" do
    sign_out :user
    ModeratorController.action_methods.each do |path|
      get path
      assert_response(404)
    end
  end

  test "should require moderator status to access pages" do
    sign_in users(:standard_user)
    ModeratorController.action_methods.each do |path|
      get path
      assert_response(404)
    end
  end
end
