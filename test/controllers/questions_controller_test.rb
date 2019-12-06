require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should get index" do
    get :index
    assert_not_nil assigns(:questions)
    assert_equal Question.undeleted.count, assigns(:questions).size
    assert_response(200)
  end

  test "should get show question page" do
    get :show, params: { id: posts(:question_one).id }
    assert_not_nil assigns(:question)
    assert_not_nil assigns(:answers)
    assert_response(200)
  end

  test "should get show question page with deleted question" do
    sign_in users(:deleter)
    get :show, params: { id: posts(:deleted).id }
    assert_not_nil assigns(:question)
    assert_not_nil assigns(:answers)
    assert_response(200)
  end

  test "should get show question page with closed question" do
    sign_in users(:closer)
    get :show, params: { id: posts(:closed).id }
    assert_response 200
    assert_not_nil assigns(:question)
    assert_not_nil assigns(:answers)
  end

  test "should get tagged page" do
    get :tagged, params: { tag: "discussion" }
    assert_not_nil assigns(:questions)
    assert_response(200)
  end

  test "should get new question page" do
    sign_in users(:standard_user)
    get :new
    assert_not_nil assigns(:question)
    assert_response(200)
  end

  test "should create new question" do
    sign_in users(:standard_user)
    post :create, params: { question: { title: "ABCDEF GHIJKL MNOPQR", body_markdown: "ABCDEF GHIJKL MNOPQR STUVWX YZ",
                                        tags_cache: "discussion support" } }
    assert_not_nil assigns(:question)
    assert_equal 0, assigns(:question).score
    assert_equal ["discussion", "support"], assigns(:question).tags_cache
    assert_equal ["discussion", "support"], assigns(:question).tags.map(&:name)
    assert_response(302)
  end

  test "should get edit question page" do
    sign_in users(:editor)
    get :edit, params: { id: posts(:question_one).id }
    assert_not_nil assigns(:question)
    assert_response(200)
  end

  test "should update existing question" do
    sign_in users(:editor)
    patch :update, params: { id: posts(:question_one).id, question: { title: "ABCDEF GHIJKL MNOPQR",
                                                                      body_markdown: "ABCDEF GHIJKL MNOPQR STUVWX YZ",
                                                                      tags_cache: "discussion support" } }
    assert_not_nil assigns(:question)
    assert_equal ["discussion", "support"], assigns(:question).tags_cache
    assert_equal ["discussion", "support"], assigns(:question).tags.map(&:name)
    assert_response(302)
  end

  test "should mark question deleted" do
    sign_in users(:deleter)
    delete :destroy, params: { id: posts(:question_one).id }
    assert_not_nil assigns(:question)
    assert_equal true, assigns(:question).deleted
    assert_response(302)
  end

  test "should mark question undeleted" do
    sign_in users(:deleter)
    delete :undelete, params: { id: posts(:question_one).id }
    assert_not_nil assigns(:question)
    assert_equal false, assigns(:question).deleted
    assert_response(302)
  end

  test "should require authentication to get new question page" do
    sign_out :user
    get :new
    assert_response(302)
  end

  test "should require authentication to create new question" do
    sign_out :user
    post :create
    assert_response(302)
  end

  test "should require authentication to get edit question page" do
    sign_out :user
    get :edit, params: { id: posts(:question_one).id }
    assert_response(302)
  end

  test "should require authentication to update existing question" do
    sign_out :user
    patch :update, params: { id: posts(:question_one).id }
    assert_response(302)
  end

  test "should require authentication to mark question deleted" do
    sign_out :user
    delete :destroy, params: { id: posts(:question_one).id }
    assert_response(302)
  end

  test "should require authentication to undelete question" do
    sign_out :user
    delete :undelete, params: { id: posts(:question_one).id }
    assert_response(302)
  end

  test "should require edit privileges to get edit page" do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:question_two).id }
    assert_response(401)
  end

  test "should require edit privileges to update existing question" do
    sign_in users(:standard_user)
    patch :update, params: { id: posts(:question_two).id }
    assert_response(401)
  end

  test "should require delete privileges to mark question deleted" do
    sign_in users(:editor)
    delete :destroy, params: { id: posts(:question_one).id }
    assert_response(302)
    assert_not_nil flash[:danger]
  end

  test "should require delete privileges to undelete question" do
    sign_in users(:editor)
    delete :undelete, params: { id: posts(:question_one).id }
    assert_response(302)
    assert_not_nil flash[:danger]
  end

  test "should require viewdeleted privileges to view deleted question" do
    sign_in users(:editor)
    get :show, params: { id: posts(:deleted).id }
    assert_response(401)
  end

  test "should prevent questions having more than 5 tags" do
    sign_in users(:standard_user)
    post :create, params: { question: { title: "ABCDEF GHIJKL MNOPQR", body_markdown: "ABCDEF GHIJKL MNOPQR STUVWX YZ",
                                        tags_cache: "discussion support bug feature-request faq status-completed" } }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent questions having no tags" do
    sign_in users(:standard_user)
    post :create, params: { question: { title: "ABCDEF GHIJKL MNOPQR", body_markdown: "ABCDEF GHIJKL MNOPQR STUVWX YZ",
                                        tags_cache: "" } }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent tags being too long" do
    sign_in users(:standard_user)
    post :create, params: { question: { title: "ABCDEF GHIJKL MNOPQR", body_markdown: "ABCDEF GHIJKL MNOPQR STUVWX YZ",
                                        tags_cache: "123456789012345678901" } }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent body being whitespace" do
    sign_in users(:standard_user)
    post :create, params: { question: { title: "ABCDEF GHIJKL MNOPQR", body_markdown: " "*31, tags_cache: "discussion" } }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent title being whitespace" do
    sign_in users(:standard_user)
    post :create, params: { question: { title: " "*16, body_markdown: "ABCDEF GHIJKL MNOPQR STUVWX YZ", tags_cache: "discussion" } }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should close question" do
    sign_in users(:closer)
    patch :close, params: { id: posts(:question_one).id }
    assert_not_nil assigns(:question)
    assert_equal true, assigns(:question).closed
    assert_response(302)
  end

  test "should reopen question" do
    sign_in users(:closer)
    patch :reopen, params: { id: posts(:closed).id }
    assert_not_nil assigns(:question)
    assert_equal false, assigns(:question).closed
    assert_response(302)
  end

  test "should require authentication to close question" do
    sign_out :user
    patch :close, params: { id: posts(:question_one).id }
    assert_response(302)
  end

  test "should require authentication to reopen question" do
    sign_out :user
    patch :reopen, params: { id: posts(:closed).id }
    assert_response(302)
  end

  test "should require privileges to close question" do
    sign_in users(:standard_user)
    patch :close, params: { id: posts(:question_one).id }
    assert_equal false, assigns(:question).closed
    assert_response(302)
  end

  test "should require privileges to reopen question" do
    sign_in users(:standard_user)
    patch :reopen, params: { id: posts(:closed).id }
    assert_equal true, assigns(:question).closed
    assert_response(302)
  end

  test "should prevent closed questions being closed" do
    sign_in users(:closer)
    patch :close, params: { id: posts(:closed).id }
    assert_equal true, assigns(:question).closed
    assert_not_nil flash[:danger]
    assert_response(302)
  end

  test "should prevent open questions being reopened" do
    sign_in users(:closer)
    patch :reopen, params: { id: posts(:question_one).id }
    assert_equal false, assigns(:question).closed
    assert_not_nil flash[:danger]
    assert_response(302)
  end
end
