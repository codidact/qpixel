require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  # Help

  test 'can get help center' do
    get :help_center
    assert_response 200
    assert_not_nil assigns(:posts)
  end

  test 'can get help article' do
    get :document, params: { slug: posts(:help_article).doc_slug }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'moderator can get mod help article' do
    sign_in users(:moderator)
    get :document, params: { slug: posts(:mod_help_article).doc_slug }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'moderator help requires authentication' do
    get :document, params: { slug: posts(:mod_help_article).doc_slug }
    assert_response 404
    assert_not_nil assigns(:post)
  end

  test 'regular user cannot get mod help' do
    sign_in users(:standard_user)
    get :document, params: { slug: posts(:mod_help_article).doc_slug }
    assert_response 404
    assert_not_nil assigns(:post)
  end

  test 'cannot get disabled help article' do
    sign_in users(:moderator)
    get :document, params: { slug: posts(:disabled_help_article).doc_slug }
    assert_response 404
    assert_not_nil assigns(:post)
  end

  # Change category

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

  # New

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

  test 'new rejects category post type without category' do
    sign_in users(:standard_user)
    get :new, params: { post_type: post_types(:question).id }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
  end

  test 'new rejects parented post type without parent' do
    sign_in users(:standard_user)
    get :new, params: { post_type: post_types(:answer).id }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
  end

  # Create

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
    before_notifs = posts(:question_one).user.notifications.count
    post :create, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id,
                            post: { post_type_id: post_types(:answer).id, title: sample.title,
                                    body_markdown: sample.body_markdown, parent_id: posts(:question_one).id } }
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

  # Show

  test 'anonymous user can get show' do
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert_not assigns(:children).any?(&:deleted), 'Anonymous user can see deleted answers'
  end

  test 'standard user can get show' do
    sign_in users(:standard_user)
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert_not assigns(:children).any?(&:deleted), 'Anonymous user can see deleted answers'
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
    assert assigns(:children).any?(&:deleted), 'Privileged user cannot see deleted answers'
  end

  test 'show redirects parented to parent post' do
    get :show, params: { id: posts(:answer_one).id }
    assert_response 302
    assert_redirected_to post_path(posts(:answer_one).parent_id)
  end

  test 'unprivileged user cannot see post in high trust level category' do
    sign_in users(:standard_user)
    get :show, params: { id: posts(:high_trust).id }
    assert_response 404
  end

  # Edit

  test 'can get edit' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'edit requires authentication' do
    get :edit, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'cannot edit locked post' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:locked).id }
    assert_response 401
  end

  test 'cannot edit non-public post without permissions' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:blog_post).id }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
  end

  test 'author can edit non-public post' do
    sign_in users(:closer)
    get :edit, params: { id: posts(:blog_post).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'moderator can edit non-public post' do
    sign_in users(:moderator)
    get :edit, params: { id: posts(:blog_post).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  # Update

  test 'can update post' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:question_one)).count
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal sample.edit.body_markdown, assigns(:post).body_markdown
    assert_equal before_history + 1, after_history, 'No PostHistory event created on author update'
  end

  test 'moderators can update post' do
    sign_in users(:moderator)
    before_history = PostHistory.where(post: posts(:question_one)).count
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal sample.edit.body_markdown, assigns(:post).body_markdown
    assert_equal before_history + 1, after_history, 'No PostHistory event created on moderator update'
  end

  test 'update requires authentication' do
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'update by unprivileged user generates suggested edit' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    before_edits = SuggestedEdit.where(post: posts(:question_one)).count
    before_body = posts(:question_one).body_markdown
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    after_edits = SuggestedEdit.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal before_body, assigns(:post).body_markdown, 'Suggested edit incorrectly applied immediately'
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on unprivileged update'
    assert_equal before_edits + 1, after_edits, 'No SuggestedEdit created on unprivileged update'
  end

  test 'update rejects no change edit' do
    sign_in users(:standard_user)
    post = posts(:question_one)
    before_history = PostHistory.where(post: post).count
    patch :update, params: { id: post.id,
                             post: { title: post.title, body_markdown: post.body_markdown,
                                     tags_cache: post.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on no-change update'
  end

  test 'cannot update locked post' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:locked)).count
    patch :update, params: { id: posts(:locked).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 401
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on update'
  end

  test 'anyone with unrestricted can update free-edit post' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:free_edit)).count
    patch :update, params: { id: posts(:free_edit).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:free_edit)).count
    assert_response 302
    assert_redirected_to post_path(posts(:free_edit))
    assert_not_nil assigns(:post)
    assert_equal sample.edit.body_markdown, assigns(:post).body_markdown
    assert_equal before_history + 1, after_history, 'No PostHistory event created on free-edit update'
  end

  # Close

  test 'can close question' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 200
    assert_not_nil assigns(:post)
    assert_equal before_history + 1, after_history, 'PostHistory event not created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'close requires authentication' do
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:not_good).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot close' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 403
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot close a closed post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:closed)).count
    post :close, params: { id: posts(:closed).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:closed)).count
    assert_response 400
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'close rejects nonexistent close reason' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: -999 }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 404
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'close ensures other post exists if reason requires it' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:duplicate) }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 400
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot close a locked post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :close, params: { id: posts(:locked).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 401
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on close'
  end

  # Reopen

  test 'can reopen question' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:closed)).count
    post :reopen, params: { id: posts(:closed).id }
    after_history = PostHistory.where(post: posts(:closed)).count
    assert_response 302
    assert_redirected_to post_path(posts(:closed))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on reopen'
  end

  test 'reopen requires authentication' do
    post :reopen, params: { id: posts(:closed).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot reopen' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:closed)).count
    post :reopen, params: { id: posts(:closed).id }
    after_history = PostHistory.where(post: posts(:closed)).count
    assert_response 302
    assert_redirected_to post_path(posts(:closed))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on reopen'
  end

  test 'cannot reopen an open post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :reopen, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on reopen'
  end

  test 'cannot reopen a locked post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :reopen, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 401
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on reopen'
  end

  # Delete

  test 'can delete post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:question_two)).count
    post :delete, params: { id: posts(:question_two).id }
    after_history = PostHistory.where(post: posts(:question_two)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on deletion'
  end

  test 'delete requires authentication' do
    post :delete, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot delete' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :delete, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a post with responses' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :delete, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a deleted post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:deleted)).count
    post :delete, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a locked post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :delete, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 401
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'delete ensures all children are deleted' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post_id: posts(:bad_answers).children.map(&:id)).count
    post :delete, params: { id: posts(:bad_answers).id }
    after_history = PostHistory.where(post_id: posts(:bad_answers).children.map(&:id)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert assigns(:post).children.all?(&:deleted), 'Answers not deleted with question'
    assert_equal before_history + posts(:bad_answers).children.count, after_history,
                 'Answer PostHistory events not created on question deletion'
  end

  # Restore

  test 'can restore post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:deleted)).count
    post :restore, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on deletion'
  end

  test 'restore requires authentication' do
    post :restore, params: { id: posts(:deleted).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot restore' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:deleted)).count
    post :restore, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot restore a post deleted by a moderator' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:deleted_mod)).count
    post :restore, params: { id: posts(:deleted_mod).id }
    after_history = PostHistory.where(post: posts(:deleted_mod)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot restore a restored post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :restore, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot restore a locked post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :restore, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 401
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'restore brings back all answers deleted after question' do
    sign_in users(:deleter)
    deleted_at = posts(:deleted).deleted_at
    children = posts(:deleted).children.where('deleted_at >= ?', deleted_at)
    children_count = children.count
    before_history = PostHistory.where(post_id: children.where('deleted_at >= ?', deleted_at)).count
    post :restore, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post_id: children.where('deleted_at >= ?', deleted_at)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + children_count, after_history,
                 'Answer PostHistory events not created on question restore'
  end

  # Toggle comments

  test 'can toggle comments' do
    sign_in users(:moderator)
    post :toggle_comments, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert assigns(:post).comments_disabled
  end

  test 'toggle comments requires authentication' do
    post :toggle_comments, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'regular users cannot toggle comments' do
    sign_in users(:standard_user)
    post :toggle_comments, params: { id: posts(:question_one).id }
    assert_response 404
    assert_not_nil assigns(:post)
    assert_not assigns(:post).comments_disabled
  end

  test 'specifying delete all results in comments being deleted' do
    sign_in users(:moderator)
    post :toggle_comments, params: { id: posts(:question_one).id, delete_all_comments: true }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert assigns(:post).comments_disabled
    assert assigns(:post).comments.all?(&:deleted?)
  end

  # Lock

  test 'can lock post' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:question_one).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 7.days.from_now
    assert assigns(:post).locked_until >= 7.days.from_now - 1.minute
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'lock requires authentication' do
    post :lock, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot lock' do
    sign_in users(:standard_user)
    post :lock, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot lock locked post' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:locked).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot lock longer than 30 days' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:question_one).id, length: 60, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 30.days.from_now
    assert assigns(:post).locked_until >= 30.days.from_now - 1.minute
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'moderator can lock longer than 30 days' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, length: 60, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 60.days.from_now
    assert assigns(:post).locked_until >= 60.days.from_now - 1.minute
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'moderator can lock indefinitely' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nil assigns(:post).locked_until
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  # Unlock

  test 'can unlock post' do
    sign_in users(:deleter)
    posts(:locked).update(locked_until: 2.days.from_now)
    post :unlock, params: { id: posts(:locked).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'unlock requires authentication' do
    post :unlock, params: { id: posts(:locked).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot unlock' do
    sign_in users(:standard_user)
    post :unlock, params: { id: posts(:locked).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot unlock unlocked post' do
    sign_in users(:deleter)
    post :unlock, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot unlock post locked by moderator' do
    sign_in users(:deleter)
    posts(:locked_mod).update(locked_until: 2.days.from_now)
    post :unlock, params: { id: posts(:locked_mod).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_equal ['locked_by_mod'], JSON.parse(response.body)['errors']
  end

  # Feature

  test 'can feature post' do
    sign_in users(:moderator)
    before_audits = AuditLog.count
    post :feature, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:link).id
    assert_equal before_audits + 1, AuditLog.count, 'AuditLog not created on post feature'
  end

  test 'feature requires authentication' do
    post :feature, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'regular user cannot feature' do
    sign_in users(:deleter)
    post :feature, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ['no_privilege'], JSON.parse(response.body)['errors']
  end

  # Save draft

  test 'can save draft' do
    sign_in users(:standard_user)
    post :save_draft, params: { path: 'test', post: 'test' }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal "saved_post.#{users(:standard_user).id}.test", JSON.parse(response.body)['key']
    assert_equal 'test', RequestContext.redis.get(JSON.parse(response.body)['key'])
  end

  # Delete draft

  test 'can delete draft' do
    sign_in users(:standard_user)
    post :delete_draft, params: { path: 'test' }
    assert_response 200
  end
end
