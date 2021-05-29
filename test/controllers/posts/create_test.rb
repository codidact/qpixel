require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can create help post' do
    sign_in users(:moderator)
    post :create, params: { post_type: post_types(:help_doc).id,
                            post: { post_type_id: post_types(:help_doc).id, title: sample.title, doc_slug: 'topic',
                                    body_markdown: sample.body_markdown, help_category: 'A', help_ordering: '99' } }
    assert_response 302
    assert_not_nil assigns(:post).id
    assert_redirected_to help_path(assigns(:post).doc_slug)
  end

  test 'can create category post' do
    sign_in users(:standard_user)
    post :create, params: { post_type: post_types(:question).id, category: categories(:main).id,
                            post: { post_type_id: post_types(:question).id, title: sample.title,
                                    body_markdown: sample.body_markdown, category_id: categories(:main).id,
                                    tags_cache: sample.tags_cache, license_id: licenses(:cc_by_sa).id } }
    assert_response 302
    assert_not_nil assigns(:post).id
    assert_redirected_to post_path(assigns(:post))
  end

  test 'can create answer' do
    sign_in users(:closer)
    before_notifs = posts(:question_one).user.notifications.count
    post :create, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id,
                            post: { post_type_id: post_types(:answer).id, title: sample.title,
                                    body_markdown: sample.body_markdown, parent_id: posts(:question_one).id,
                                    license_id: licenses(:cc_by_sa).id } }
    after_notifs = posts(:question_one).user.notifications.count
    assert_response 302
    assert_not_nil assigns(:post).id
    assert_equal before_notifs + 1, after_notifs, 'Notification not created on answer create'
    assert_redirected_to post_path(posts(:question_one).id, anchor: "answer-#{assigns(:post).id}")
  end

  test 'create requires authentication' do
    post :create, params: { post_type: post_types(:question).id, category: categories(:main).id,
                            post: { post_type_id: post_types(:question).id, title: sample.title,
                                    body_markdown: sample.body_markdown, category_id: categories(:main).id,
                                    tags_cache: sample.tags_cache } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'standard users cannot create help posts' do
    sign_in users(:standard_user)
    post :create, params: { post_type: post_types(:help_doc).id,
                            post: { post_type_id: post_types(:help_doc).id, title: sample.title, doc_slug: 'topic',
                                    body_markdown: sample.body_markdown, help_category: 'A', help_ordering: '99' } }
    assert_response 404
  end

  test 'moderators cannot create policy posts' do
    sign_in users(:moderator)
    post :create, params: { post_type: post_types(:policy_doc).id,
                            post: { post_type_id: post_types(:policy_doc).id, title: sample.title, doc_slug: 'topic',
                                    body_markdown: sample.body_markdown, help_category: 'A', help_ordering: '99' } }
    assert_response 404
  end

  test 'category post type rejects without category' do
    sign_in users(:standard_user)
    post :create, params: { post_type: post_types(:question).id,
                            post: { post_type_id: post_types(:question).id, title: sample.title,
                                    body_markdown: sample.body_markdown, tags_cache: sample.tags_cache } }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
    assert_nil assigns(:post).id
  end

  test 'category post type checks required trust level' do
    sign_in users(:standard_user)
    post :create, params: { post_type: post_types(:question).id, category: categories(:high_trust).id,
                            post: { post_type_id: post_types(:question).id, title: sample.title,
                                    body_markdown: sample.body_markdown, category_id: categories(:high_trust).id,
                                    tags_cache: sample.tags_cache } }
    assert_response 403
    assert_nil assigns(:post).id
    assert_not_empty assigns(:post).errors.full_messages
  end

  test 'parented post type rejects without parent' do
    sign_in users(:standard_user)
    post :create, params: { post_type: post_types(:answer).id,
                            post: { post_type_id: post_types(:answer).id, title: sample.title,
                                    body_markdown: sample.body_markdown } }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
    assert_nil assigns(:post).id
  end

  test 'create ensures community user is created' do
    user = users(:no_community_user)
    before = CommunityUser.where(user: user, community: communities(:sample)).count

    sign_in user
    post :create, params: { post_type: post_types(:question).id, category: categories(:main).id,
                            post: { post_type_id: post_types(:question).id, title: sample.title,
                                    body_markdown: sample.body_markdown, category_id: categories(:main).id,
                                    tags_cache: sample.tags_cache } }

    after = CommunityUser.where(user: user, community: communities(:sample)).count
    assert_equal before + 1, after, 'No CommunityUser record was created'
  end
end
