require 'test_helper'

class FlagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should create new post flag' do
    sign_in users(:standard_user)

    try_create_flag(posts(:answer_two), reason: 'testing post flags')

    assert_response(:created)

    @flag = assigns(:flag)
    assert_not_nil @flag
    assert_not_nil @flag.post
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal I18n.t('flags.success.create_generic'), JSON.parse(response.body)['message']
  end

  test 'should create new comment flag' do
    sign_in users(:standard_user)

    try_create_flag(comments(:one), reason: 'testing comment flags')

    assert_response(:created)

    @flag = assigns(:flag)
    assert_not_nil @flag
    assert_not_nil @flag.post
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should fail to create invalid flags' do
    sign_in users(:standard_user)

    try_create_flag(posts(:question_one), reason: 'a' * 1001)

    assert_response(:bad_request)
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_equal I18n.t('flags.errors.create_generic'), JSON.parse(response.body)['message']
  end

  test 'should fail to create flags for rate-limited users' do
    {
      RL_NewUserFlags: users(:basic_user),
      RL_Flags: users(:standard_user)
    }.each_pair do |setting, user|
      sign_in(user)

      SiteSetting[setting] = 0

      try_create_flag(posts(:question_one), reason: 'testing flag rate limits')

      assert_response(:forbidden)
      assert_equal 'failed', JSON.parse(response.body)['status']
      assert_equal I18n.t('flags.errors.rate_limited', count: 0), JSON.parse(response.body)['message']
    end
  end

  test 'flag queues should require authentication' do
    [:escalated_queue, :handled, :queue].each do |action|
      get action
      assert_redirected_to_sign_in
    end
  end

  test 'unprivileged users should not be able to access flag queues' do
    sign_in users(:standard_user)

    [:escalated_queue, :handled, :queue].each do |action|
      get action
      assert_response(:not_found)
    end
  end

  test 'moderators should be able to access flag queues' do
    sign_in users(:moderator)

    [:handled, :queue].each do |action|
      get action
      assert_response(:success)
      assert_not_nil assigns(:flags)
      # TODO: add assertions for correct flag types
    end
  end

  test 'admins should be able to access escalated flag queues' do
    sign_in users(:admin)

    get :escalated_queue

    assert_response(:success)
    assert_not_nil assigns(:flags)
  end

  test 'should add status to flag' do
    sign_in users(:moderator)

    try_resolve_flag(flags(:one), result: 'Helpful', message: 'Please send us more flags')

    assert_not_nil assigns(:flag)
    assert_not_nil assigns(:flag).status
    assert_not_nil assigns(:flag).handled_by
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(:success)
  end

  test 'should require authentication to create flag' do
    sign_out :user
    post :new
    assert_response(:found)
  end

  test 'should require authentication to resolve flag' do
    sign_out :user
    try_resolve_flag(flags(:one))
    assert_response(:found)
  end

  test 'should require moderator status to resolve flag' do
    sign_in users(:standard_user)
    try_resolve_flag(flags(:one))
    assert_response(:not_found)
  end

  test 'should not allow non-moderator users to resolve flags on themselves' do
    sign_in users(:deleter)
    try_resolve_flag(flags(:on_deleter))
    assert_response(:not_found)
  end

  test 'should not allow non-moderator users to resolve confidential flags' do
    sign_in users(:deleter)
    try_resolve_flag(flags(:confidential_on_deleter))
    assert_response(:not_found)
  end

  test 'non-moderator users should only see their flag history' do
    mod_user = users(:moderator)
    std_user = users(:standard_user)

    sign_in std_user
    get :history, params: { id: mod_user.id }
    assert_response(:not_found)

    get :history, params: { id: std_user.id }
    assert_response(:success)

    sign_in mod_user
    get :history, params: { id: std_user.id }
    assert_response(:success)
  end

  private

  def try_create_flag(target, **opts)
    post :new, params: { post_id: target.id,
                         post_type: target.is_a?(Post) ? 'Post' : 'Comment' }.merge(opts)
  end

  def try_resolve_flag(flag, result: nil, message: nil)
    post :resolve, params: { id: flag.id, result: result, message: message }
  end
end
