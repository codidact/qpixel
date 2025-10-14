require 'test_helper'

class ComplaintsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get safety center' do
    get safety_center_path
    assert_response(:success)
  end

  test 'safety center should work signed in' do
    sign_in users(:basic_user)
    get safety_center_path
    assert_response(:success)
  end

  test 'safety center should work for staff' do
    sign_in users(:staff)
    get safety_center_path
    assert_response(:success)
  end

  test 'new report should work signed out' do
    get new_complaint_path
    assert_response(:success)
  end

  test 'new report should work signed in' do
    sign_in users(:basic_user)
    get new_complaint_path
    assert_response(:success)
  end

  test 'new report should work for staff' do
    sign_in users(:staff)
    get new_complaint_path
    assert_response(:success)
  end

  test 'should use signed in user email if available' do
    sign_in users(:basic_user)
    try_create_report report_type: 'illegal', reported_url: 'https://example.com', content_type: 'fraud',
                      content: 'test', email: 'something@else.com', user_wants_updates: true
    assert_response(:found)
    assert_not_nil assigns(:complaint)
    assert_redirected_to complaint_path(assigns(:complaint).access_token)
    assert_equal users(:basic_user).email, assigns(:complaint).email
  end

  test 'should create report for anonymous user and use email provided' do
    try_create_report report_type: 'illegal', reported_url: 'https://example.com', content_type: 'fraud',
                      content: 'test', email: 'something@else.com', user_wants_updates: true
    assert_response(:found)
    assert_not_nil assigns(:complaint)
    assert_redirected_to complaint_path(assigns(:complaint).access_token)
    assert_equal 'something@else.com', assigns(:complaint).email
  end

  test 'should correctly validate fields for report' do
    try_create_report user_wants_updates: true
    assert_response(:bad_request)
    assert_not_nil assigns(:complaint)
    assert_equal 3, assigns(:errors).size
  end

  test 'should correct validate missing comment' do
    try_create_report report_type: 'illegal', reported_url: 'https://example.com', content_type: 'fraud',
                      email: 'test@example.com', user_wants_updates: true
    assert_response(:bad_request)
    assert_not_nil assigns(:complaint)
    assert_equal 1, assigns(:errors).size
  end

  test 'show should work for anonymous user' do
    try_show_report :anonymous
    assert_response(:success)
    assert_not_nil assigns(:complaint)
    assert_not_nil assigns(:report_type)
    assert_not_nil assigns(:content_type)
    assert_not_nil assigns(:status)
  end

  test 'should prevent anonymous user accessing a report with a user' do
    try_show_report :illegal
    assert_response(:not_found)
  end

  test 'show should work for signed in user on own report' do
    sign_in users(:basic_user)
    try_show_report :illegal
    assert_response(:success)
    assert_not_nil assigns(:complaint)
  end

  test 'should prevent signed in user accessing anonymous report' do
    sign_in users(:basic_user)
    try_show_report :anonymous
    assert_response(:not_found)
  end

  test 'should prevent signed in user accessing report of another user' do
    sign_in users(:basic_user)
    try_show_report :assigned
    assert_response(:not_found)
  end

  test 'should allow staff to access anonymous report' do
    sign_in users(:staff)
    try_show_report :anonymous
    assert_response(:success)
    assert_not_nil assigns(:complaint)
  end

  test 'should allow staff to access report of another user' do
    sign_in users(:staff)
    try_show_report :illegal
    assert_response(:success)
    assert_not_nil assigns(:complaint)
  end

  test 'should allow anonymous user to comment on report (HTML, redirect)' do
    try_comment :anonymous
    assert_response(:found)
    assert_not_nil assigns(:complaint)
    assert_not_nil assigns(:comment)
    assert_redirected_to complaint_path(assigns(:complaint).access_token)
    assert_empty assigns(:comment).errors.full_messages
    assert_nil flash[:danger]
  end

  test 'should allow anonymous user to comment on report (JSON)' do
    try_comment :anonymous, format: :json
    assert_response(:success)
    assert_valid_json_response
    assert_not_nil assigns(:complaint)
    assert_not_nil assigns(:comment)
    assert_empty assigns(:comment).errors.full_messages
    assert_nil flash[:danger]
  end

  test 'should allow signed in user to comment on report' do
    sign_in users(:basic_user)
    try_comment :illegal
    assert_response(:found)
    assert_not_nil assigns(:complaint)
    assert_not_nil assigns(:comment)
    assert_redirected_to complaint_path(assigns(:complaint).access_token)
    assert_empty assigns(:comment).errors.full_messages
    assert_nil flash[:danger]
  end

  test 'should allow staff to comment on report' do
    sign_in users(:staff)
    try_comment :illegal
    assert_response(:found)
    assert_not_nil assigns(:complaint)
    assert_not_nil assigns(:comment)
    assert_redirected_to complaint_path(assigns(:complaint).access_token)
    assert_empty assigns(:comment).errors.full_messages
    assert_nil flash[:danger]
  end

  test 'should prevent anonymous user from commenting on report from another user' do
    try_comment :illegal
    assert_response(:not_found)
  end

  test 'should prevent signed in user from commenting on report from another user' do
    sign_in users(:basic_user)
    try_comment :assigned
    assert_response(:not_found)
  end

  test 'should prevent reporter adding multiple consecutive comments' do
    sign_in users(:basic_user)
    try_comment :responded
    assert_response(:found)
    assert_not_empty assigns(:comment).errors.full_messages
    assert_not_nil flash[:danger]
  end

  test 'should prevent user from adding internal comment' do
    try_comment :anonymous, internal: true
    assert_response(:found)
    assert_equal false, assigns(:comment).internal
  end

  test 'should allow staff to add internal comment' do
    sign_in users(:staff)
    try_comment :anonymous, internal: true
    assert_response(:found)
    assert_equal true, assigns(:comment).internal
  end

  private

  def try_create_report(**params)
    post create_complaint_path, params: params
  end

  def try_show_report(complaint_sym)
    get complaint_path(complaints(complaint_sym).access_token)
  end

  def try_comment(complaint_sym, internal: false, content: 'test', format: :html)
    post create_complaint_comment_path(complaints(complaint_sym).access_token,
                                       params: { content: content, internal: internal },
                                       formats: [format])
  end
end
