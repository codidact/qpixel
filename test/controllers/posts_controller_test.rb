require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should successfully get help center' do
    get :help_center
    assert_response 200
    assert_not_nil assigns(:posts)
  end

  test 'question permalink should correctly redirect' do
    get :share_q, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to question_path(posts(:question_one))
  end

  test 'answer permalink should correctly redirect' do
    get :share_a, params: { qid: posts(:question_one).id, id: posts(:answer_one).id }
    assert_response 302
    assert_redirected_to question_path(id: posts(:question_one).id, anchor: "answer-#{posts(:answer_one).id}")
  end

  test 'should change category' do
    sign_in users(:deleter)
    post :change_category, params: { id: posts(:article_one).id, target_id: categories(:articles_only).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:target)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal categories(:articles_only).id, assigns(:post).category_id
  end

  test 'should deny change category to unprivileged' do
    sign_in users(:standard_user)
    post :change_category, params: { id: posts(:article_one).id, target_id: categories(:articles_only).id }
    assert_response 403
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ["You don't have permission to make that change."], JSON.parse(response.body)['errors']
  end

  test 'should refuse to change category of wrong post type' do
    sign_in users(:deleter)
    post :change_category, params: { id: posts(:question_one).id, target_id: categories(:articles_only).id }
    assert_response 409
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ["This post type is not allowed in the #{categories(:articles_only).name} category."],
                 JSON.parse(response.body)['errors']
  end

  test 'should get new' do
    sign_in users(:moderator)
    get :new, params: { post_type: post_types(:help_doc).id }
    assert_nil flash[:danger]
    assert_response 200

    get :new, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id }
    assert_nil flash[:danger]
    assert_response 200

    get :new, params: { post_type: post_types(:question).id, category: categories(:main).id }
    assert_nil flash[:danger]
    assert_response 200
  end

  test 'new requires authentication' do
    get :new, params: { post_type: post_types(:help_doc).id }
    assert_redirected_to new_user_session_path
    get :new, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id }
    assert_redirected_to new_user_session_path
    get :new, params: { post_type: post_types(:question).id, category: categories(:main).id }
    assert_redirected_to new_user_session_path
  end

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
                                    tags_cache: sample.tags_cache } }
    assert_response 302
    assert_not_nil assigns(:post).id
    assert_redirected_to post_path(assigns(:post))
  end

  test 'can create answer' do
    sign_in users(:standard_user)
    post :create, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id,
                            post: { post_type_id: post_types(:answer).id, title: sample.title,
                                    body_markdown: sample.body_markdown, parent_id: posts(:question_one).id } }
    assert_response 302
    assert_not_nil assigns(:post).id
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

  test 'anonymous user can get show' do
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert_not assigns(:children).any? { |c| c.deleted }, 'Anonymous user can see deleted answers'
  end

  test 'standard user can get show' do
    sign_in users(:standard_user)
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert_not assigns(:children).any? { |c| c.deleted }, 'Anonymous user can see deleted answers'
  end

  test 'privileged user can see deleted post' do
    sign_in users(:deleter)
    get :show, params: { id: posts(:deleted).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
  end

  test 'privileged user can see deleted answers' do
    sign_in users(:deleter)
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert assigns(:children).any? { |c| c.deleted }, 'Privileged user cannot see deleted answers'
  end

  test 'show redirects parented to parent post' do
    get :show, params: { id: posts(:answer_one).id }
    assert_response 302
    assert_redirected_to post_path(posts(:answer_one).parent_id)
  end
end
