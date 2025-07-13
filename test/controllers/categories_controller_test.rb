require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    get :index
    assert_response(:success)
    assert_not_nil assigns(:categories)
  end

  test 'should get show' do
    get :show, params: { id: categories(:main).id }
    assert_response(:success)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)
  end

  test 'fake community should not get show' do
    RequestContext.community = communities(:fake)
    request.env['HTTP_HOST'] = 'fake.qpixel.com'

    get :show, params: { id: categories(:main).id }
    assert_response(:not_found)
  end

  test 'should require authentication to get new' do
    get :new
    assert_redirected_to_sign_in
  end

  test 'should require admin to get new' do
    sign_in users(:standard_user)
    get :new
    assert_response(:not_found)
  end

  test 'should allow admins to get new' do
    sign_in users(:admin)
    get :new
    assert_response(:success)
    assert_not_nil assigns(:category)
  end

  test 'should require authentication to create category' do
    post :create, params: { category: { name: 'test', short_wiki: 'test', display_post_types: [Question.post_type_id],
                                        post_type_ids: [Question.post_type_id, Answer.post_type_id],
                                        tag_set: tag_sets(:main).id, color_code: 'blue',
                                        license_id: licenses(:cc_by_sa).id } }

    assert_redirected_to_sign_in
  end

  test 'should require admin to create category' do
    sign_in users(:standard_user)
    post :create, params: { category: { name: 'test', short_wiki: 'test', display_post_types: [Question.post_type_id],
                                        post_type_ids: [Question.post_type_id, Answer.post_type_id],
                                        tag_set: tag_sets(:main).id, color_code: 'blue',
                                        license_id: licenses(:cc_by_sa).id } }
    assert_response(:not_found)
  end

  test 'should allow admins to create category' do
    sign_in users(:admin)
    post :create, params: { category: { name: 'test', short_wiki: 'test', display_post_types: [Question.post_type_id],
                                        post_type_ids: [Question.post_type_id, Answer.post_type_id],
                                        tag_set_id: tag_sets(:main).id, color_code: 'blue',
                                        license_id: licenses(:cc_by_sa).id } }

    assert_response(:found)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:category).id
    assert_equal false, assigns(:category).errors.any?
    assert_redirected_to category_path(assigns(:category))
  end

  test ':show should only succeed for users who can see the category in the first place' do
    users.each do |user|
      sign_in user

      categories.each do |category|
        try_show_category(category)

        if category.public? || user.can_see_category?(category)
          assert_response(:success)
        else
          assert_response(:not_found)
        end

        assert_not_nil assigns(:category)
      end
    end
  end

  private

  def try_show_category(category)
    get :show, params: { id: category.id }
  end
end
