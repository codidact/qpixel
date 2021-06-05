require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    get :index
    assert_response 200
    assert_not_nil assigns(:categories)
  end

  test 'should get show' do
    get :show, params: { id: categories(:main).id }
    assert_response 200
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)
  end

  test 'fake community should not get show' do
    RequestContext.community = communities(:fake)
    request.env['HTTP_HOST'] = 'fake.qpixel.com'

    get :show, params: { id: categories(:main).id }
    assert_response(404)
  end

  test 'should require authentication to get new' do
    get :new
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should require admin to get new' do
    sign_in users(:standard_user)
    get :new
    assert_response 404
  end

  test 'should allow admins to get new' do
    sign_in users(:admin)
    get :new
    assert_response 200
    assert_not_nil assigns(:category)
  end

  test 'should require authentication to create category' do
    post :create, params: { category: { name: 'test', short_wiki: 'test', display_post_types: [Question.post_type_id],
                                        post_type_ids: [Question.post_type_id, Answer.post_type_id],
                                        tag_set: tag_sets(:main).id, color_code: 'blue',
                                        license_id: licenses(:cc_by_sa).id } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should require admin to create category' do
    sign_in users(:standard_user)
    post :create, params: { category: { name: 'test', short_wiki: 'test', display_post_types: [Question.post_type_id],
                                        post_type_ids: [Question.post_type_id, Answer.post_type_id],
                                        tag_set: tag_sets(:main).id, color_code: 'blue',
                                        license_id: licenses(:cc_by_sa).id } }
    assert_response 404
  end

  test 'should allow admins to create category' do
    sign_in users(:admin)
    post :create, params: { category: { name: 'test', short_wiki: 'test', display_post_types: [Question.post_type_id],
                                        post_type_ids: [Question.post_type_id, Answer.post_type_id],
                                        tag_set: tag_sets(:main).id, color_code: 'blue',
                                        license_id: licenses(:cc_by_sa).id } }
    assert_response 302
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:category).id
    assert_equal false, assigns(:category).errors.any?
    assert_redirected_to category_path(assigns(:category))
  end

  test 'should prevent users under min_view_trust_level viewing category that requires higher' do
    get :show, params: { id: categories(:admin_only).id }
    assert_response 404
    assert_not_nil assigns(:category)
  end
end
