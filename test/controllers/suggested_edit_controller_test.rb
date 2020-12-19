require 'test_helper'

class SuggestedEditControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get page with all pending edits' do
    get :category_index, params: { category: categories(:main).id }
    assert_response 200
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:edits)
  end

  test 'should get page with all decided edits' do
    get :category_index, params: { category: categories(:main).id, show_decided: 1 }
    assert_response 200
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:edits)
  end

  test 'should get pending suggested edit page' do
    get :show, params: { id: suggested_edits(:pending_suggested_edit).id }
    assert_not_nil assigns(:edit)
    assert_equal assigns(:edit).active, true
    assert_response(200)
  end

  test 'should get approved suggested edit page' do
    get :show, params: { id: suggested_edits(:accepted_suggested_edit).id }
    assert_not_nil assigns(:edit)
    assert_equal assigns(:edit).active, false
    assert_equal assigns(:edit).accepted, true
    assert_response(200)
  end

  test 'should get rejected suggested edit page' do
    get :show, params: { id: suggested_edits(:rejected_suggested_edit).id }
    assert_not_nil assigns(:edit)
    assert_equal assigns(:edit).active, false
    assert_equal assigns(:edit).accepted, false
    assert_response(200)
  end

  test 'signed-out shouldn\'t be able to approve' do
    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: true, accepted: false)

    post :approve, params: { id: suggested_edit.id }
    assert_response(400)
  end

  test 'signed-out shouldn\'t be able to reject' do
    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: true, accepted: false)

    post :reject, params: { id: suggested_edit.id, rejection_comment: 'WHY NOT?' }
    assert_response(400)
  end

  test 'already decided edit shouldn\'t be able to be approved' do
    sign_in users(:editor)

    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: false, accepted: false)

    post :approve, params: { id: suggested_edit.id }
    assert_response(409)
  end

  test 'already decided edit shouldn\'t be able to be rejected' do
    sign_in users(:editor)

    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: false, accepted: true)

    post :reject, params: { id: suggested_edit.id, rejection_comment: 'WHY NOT?' }
    assert_response(409)
  end

  test 'approving edit should change status and apply it' do
    sign_in users(:editor)

    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: true, accepted: false)

    post :approve, params: { id: suggested_edit.id }
    suggested_edit.reload

    assert_response(200)
    assert_not_nil assigns(:edit)

    assert_equal suggested_edit.active, false
    assert_equal suggested_edit.accepted, true
    assert_equal suggested_edit.body_markdown, suggested_edit.post.body_markdown
    assert_equal suggested_edit.tags_cache, suggested_edit.post.tags_cache
    assert_equal suggested_edit.title, suggested_edit.post.title
  end

  test 'rejecting edit should change status' do
    sign_in users(:editor)

    suggested_edit = suggested_edits(:rejected_suggested_edit)
    suggested_edit.update(active: true, accepted: false)

    post :reject, params: { id: suggested_edit.id, rejection_comment: 'WHY NOT?' }
    suggested_edit.reload

    assert_response(200)
    assert_not_nil assigns(:edit)

    assert_equal suggested_edit.active, false
    assert_equal suggested_edit.accepted, false
    assert_equal suggested_edit.rejected_comment, 'WHY NOT?'
  end
end
