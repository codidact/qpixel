require 'test_helper'

class ComplaintsControllerTest < ActionDispatch::IntegrationTest
  test 'should get safety center' do
    get safety_center_path
    assert_response :success
  end

  test 'safety center should work signed in' do
    sign_in users(:basic_user)
    get safety_center_path
    assert_response :success
  end

  test 'safety center should work for staff' do
    sign_in users(:staff)
    get safety_center_path
    assert_response :success
  end

  test 'new report should work signed out' do
    get new_complaint_path
    assert_response :success
  end

  test 'new report should work signed in' do
    sign_in users(:basic_user)
    get new_complaint_path
    assert_response :success
  end

  test 'new report should work for staff' do
    sign_in users(:staff)
    get new_complaint_path
    assert_response :success
  end
end
