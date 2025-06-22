require 'test_helper'

class ModeratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    sign_in users(:moderator)
    get :index
    assert_response(:success)
  end

  test 'should require authentication to access pages' do
    sign_out :user
    [:index, :recently_deleted_posts].each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should require moderator status to access pages' do
    sign_in users(:standard_user)
    [:index, :recently_deleted_posts].each do |path|
      get path
      assert_response(:not_found)
    end
  end

  # TODO: more descriptive test case descriptions
  test 'should get recently deleted posts page' do
    sign_in users(:moderator)
    get :recently_deleted_posts

    posts = assigns(:posts)

    assert_response(:success)
    assert_not_nil posts
    assert posts.all?(&:deleted?)
  end

  test 'should get recent comments page' do
    sign_in users(:moderator)
    get :recent_comments
    assert_response(:success)
    assert_not_nil assigns(:comments)
  end

  test 'can nominate for promotion' do
    sign_in users(:deleter)
    post :nominate_promotion, params: { id: posts(:question_one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'cannot nominate locked post' do
    sign_in users(:deleter)
    post :nominate_promotion, params: { id: posts(:locked).id, format: :json }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'nominate requires authentication' do
    post :nominate_promotion, params: { id: posts(:question_one).id }
    assert_redirected_to_sign_in
  end

  test 'unprivileged user cannot nominate' do
    sign_in users(:standard_user)
    post :nominate_promotion, params: { id: posts(:question_one).id, format: :json }

    assert_response(:not_found)
    assert_valid_json_response
    assert_equal ['no_privilege'], JSON.parse(response.body)['errors']
  end

  test 'cannot nominate second-level post' do
    sign_in users(:deleter)
    post :nominate_promotion, params: { id: posts(:answer_one).id, format: :json }

    assert_response(:not_found)
    assert_valid_json_response
    assert_equal ['unavailable_for_type'], JSON.parse(response.body)['errors']
  end

  test 'can get promotions list' do
    sign_in users(:deleter)
    get :promotions
    assert_response(:success)
    assert_not_nil assigns(:promotions)
    assert_not_nil assigns(:posts)
  end

  test 'promotions list requires auth' do
    get :promotions
    assert_redirected_to_sign_in
  end

  test 'promotions list requires privileges' do
    sign_in users(:standard_user)
    get :promotions
    assert_response(:not_found)
  end

  test 'can remove a post from promotions' do
    RequestContext.redis.set('network/promoted_posts',
                             JSON.dump({ posts(:question_one).id.to_s => 28.days.from_now.to_i }))
    sign_in users(:deleter)
    delete :remove_promotion, params: { id: posts(:question_one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal '{}', RequestContext.redis.get('network/promoted_posts')
  end

  test 'remove promotion requires auth' do
    delete :remove_promotion, params: { id: posts(:question_one).id }
    assert_redirected_to_sign_in
  end

  test 'remove promotion requires privileges' do
    sign_in users(:standard_user)

    delete :remove_promotion, params: { id: posts(:question_one).id, format: :json }

    assert_response(:not_found)
    assert_valid_json_response
    assert_equal ['no_privilege'], JSON.parse(response.body)['errors']
  end

  test 'cannot remove unpromoted post' do
    sign_in users(:deleter)

    delete :remove_promotion, params: { id: posts(:question_two).id, format: :json }

    assert_response(:not_found)
    assert_valid_json_response
    assert_equal ['not_promoted'], JSON.parse(response.body)['errors']
  end

  test 'user_vote_summary should provide correct user info' do
    std = users(:standard_user)

    sign_in users(:moderator)

    get :user_vote_summary, params: { id: std.id }

    related_votes = votes.select { |v| v.user.same_as?(std) || v.recv_user.same_as?(std) }
    user = assigns(:user)
    users = assigns(:users)

    assert_response(:success)
    assert user.same_as?(std)

    related_votes.each do |v|
      assert(users.any? { |u| u.same_as?(v.user) || u.same_as?(v.recv_user) })
    end
  end

  test 'user_vote_summary should provide correct stats for votes cast' do
    std = users(:standard_user)

    sign_in users(:moderator)

    get :user_vote_summary, params: { id: std.id }

    vote_data = assigns(:vote_data)
    votes_cast = votes.select { |v| v.user.same_as?(std) }

    assert_equal vote_data[:cast][:total], votes_cast.length

    vote_data[:cast][:breakdown].each do |data, count|
      recv_user_id, type = data
      votes = votes_cast.select { |v| v.vote_type == type && v.recv_user.id == recv_user_id }
      assert_equal count, votes.length
    end

    vote_data[:cast][:types].each do |type, count|
      votes = votes_cast.select { |v| v.vote_type == type }
      assert_equal count, votes.length
    end
  end

  test 'user_vote_summary should provide correct stats for votes received' do
    std = users(:standard_user)

    sign_in users(:moderator)

    get :user_vote_summary, params: { id: std.id }

    vote_data = assigns(:vote_data)
    votes_received = votes.select { |v| v.recv_user.same_as?(std) }

    assert_equal vote_data[:received][:total], votes_received.length

    vote_data[:received][:breakdown].each do |data, count|
      user_id, type = data
      votes = votes_received.select { |v| v.vote_type == type && v.user.id == user_id }
      assert_equal count, votes.length
    end

    vote_data[:received][:types].each do |type, count|
      votes = votes_received.select { |v| v.vote_type == type }
      assert_equal count, votes.length
    end
  end
end
