require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'index with json format should return JSON list of tags' do
    get :index, params: { format: 'json' }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_not_nil assigns(:tags)
  end

  test 'index with search params should return tags starting with search' do
    get :index, params: { format: 'json', term: 'dis' }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_not_nil assigns(:tags)
    JSON.parse(response.body).each do |tag|
      assert_equal true, tag['name'].start_with?('dis')
    end
  end

  test 'should get category tags list' do
    get :category, params: { id: categories(:main).id }
    assert_response 200
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:category)

    sign_in users(:standard_user)
    get :category, params: { id: categories(:main).id }
    assert_response 200
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:category)
  end

  test 'should get children list' do
    get :children, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 200
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:category)

    sign_in users(:standard_user)
    get :children, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 200
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:category)
  end

  test 'should get tag page and RSS' do
    get :show, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 200
    assert_not_nil assigns(:tag)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)

    sign_in users(:standard_user)
    get :show, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 200
    assert_not_nil assigns(:tag)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)
  end

  test 'should get tag RSS feed' do
    get :show, params: { id: categories(:main).id, tag_id: tags(:topic).id, format: :rss }
    assert_response 200
    assert_not_nil assigns(:tag)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)

    sign_in users(:standard_user)
    get :show, params: { id: categories(:main).id, tag_id: tags(:topic).id, format: :rss }
    assert_response 200
    assert_not_nil assigns(:tag)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)
  end

  test 'should deny edit to anonymous user' do
    get :edit, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should deny edit to unprivileged user' do
    sign_in users(:standard_user)
    get :edit, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 403
  end

  test 'should get edit' do
    sign_in users(:deleter)
    get :edit, params: { id: categories(:main).id, tag_id: tags(:topic).id }
    assert_response 200
    assert_not_nil assigns(:tag)
    assert_not_nil assigns(:category)
  end

  test 'should deny update to anonymous user' do
    patch :update, params: { id: categories(:main).id, tag_id: tags(:topic).id,
                             tag: { parent_id: tags(:discussion).id, excerpt: 'things' } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should deny update to unprivileged user' do
    sign_in users(:standard_user)
    patch :update, params: { id: categories(:main).id, tag_id: tags(:topic).id,
                             tag: { parent_id: tags(:discussion).id, excerpt: 'things' } }
    assert_response 403
  end

  test 'should update tag' do
    sign_in users(:deleter)
    patch :update, params: { id: categories(:main).id, tag_id: tags(:topic).id,
                             tag: { parent_id: tags(:discussion).id, excerpt: 'things' } }
    assert_response 302
    assert_redirected_to tag_path(id: categories(:main).id, tag_id: tags(:topic).id)
    assert_not_nil assigns(:tag)
    assert_equal tags(:discussion).id, assigns(:tag).parent_id
    assert_equal 'things', assigns(:tag).excerpt
  end

  test 'should prevent a tag being its own parent' do
    sign_in users(:deleter)
    patch :update, params: { id: categories(:main).id, tag_id: tags(:topic).id,
                             tag: { parent_id: tags(:topic).id, excerpt: 'things' } }
    assert_response 400
    assert_not_nil assigns(:tag)
    assert_equal ['A tag cannot be its own parent.'], assigns(:tag).errors.full_messages
  end

  test 'should prevent hierarchical loops' do
    sign_in users(:deleter)
    patch :update, params: { id: categories(:main).id, tag_id: tags(:topic).id,
                             tag: { parent_id: tags(:child).id, excerpt: 'things' } }
    assert_response 400
    assert_not_nil assigns(:tag)
    assert_equal ["The #{tags(:child).name} tag is already a child of this tag."], assigns(:tag).errors.full_messages
  end
end
