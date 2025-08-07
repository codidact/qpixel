require 'test_helper'

class SuggestedEditControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get page with all pending edits' do
    get :category_index, params: { category: categories(:main).id }
    assert_response(:success)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:edits)
  end

  test 'should get page with all decided edits' do
    get :category_index, params: { category: categories(:main).id, show_decided: 1 }
    assert_response(:success)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:edits)
  end

  test 'should get pending suggested edit page' do
    get :show, params: { id: suggested_edits(:pending_suggested_edit).id }
    assert_not_nil assigns(:edit)
    assert_equal assigns(:edit).active, true
    assert_response(:success)
  end

  test 'should get approved suggested edit page' do
    get :show, params: { id: suggested_edits(:accepted_suggested_edit).id }
    assert_not_nil assigns(:edit)
    assert_equal assigns(:edit).active, false
    assert_equal assigns(:edit).accepted, true
    assert_response(:success)
  end

  test 'should get rejected suggested edit page' do
    get :show, params: { id: suggested_edits(:rejected_suggested_edit).id }
    assert_not_nil assigns(:edit)
    assert_equal assigns(:edit).active, false
    assert_equal assigns(:edit).accepted, false
    assert_response(:success)
  end

  test 'signed-out shouldn\'t be able to approve' do
    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: true, accepted: false)

    post :approve, params: { id: suggested_edit.id }
    assert_response(:forbidden)
  end

  test 'signed-out shouldn\'t be able to reject' do
    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: true, accepted: false)

    post :reject, params: { id: suggested_edit.id, rejection_comment: 'WHY NOT?' }
    assert_response(:forbidden)
  end

  test 'users without the ability to edit posts shouldn\'t be able to approve' do
    sign_in users(:moderator)

    edit = suggested_edits(:pending_high_trust)

    post :approve, params: { id: edit.id, format: 'json' }

    assert_response(:forbidden)
    assert_valid_json_response

    res_body = JSON.parse(response.body)
    assert_equal 'error', res_body['status']
    assert_not_empty res_body['message']
  end

  test 'users without the ability to edit posts shouldn\'t be able to reject' do
    sign_in users(:moderator)

    edit = suggested_edits(:pending_high_trust)

    post :reject, params: { id: edit.id, format: 'json' }

    assert_response(:forbidden)
    assert_valid_json_response

    res_body = JSON.parse(response.body)
    assert_equal 'error', res_body['status']
    assert_not_empty res_body['message']
  end

  test 'already decided edit shouldn\'t be able to be approved' do
    sign_in users(:editor)

    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: false, accepted: false)

    post :approve, params: { id: suggested_edit.id }
    assert_response(:conflict)
  end

  test 'already decided edit shouldn\'t be able to be rejected' do
    sign_in users(:editor)

    suggested_edit = suggested_edits(:accepted_suggested_edit)
    suggested_edit.update(active: false, accepted: true)

    post :reject, params: { id: suggested_edit.id, rejection_comment: 'WHY NOT?' }
    assert_response(:conflict)
  end

  test 'approving edit should change status and apply it' do
    sign_in users(:editor)

    post :approve, params: { id: suggested_edits(:pending_suggested_edit).id }

    assert_response(:success)

    @edit = assigns(:edit)

    assert_not_nil @edit
    assert_equal @edit.active, false
    assert_equal @edit.accepted, true
    assert_equal @edit.body_markdown, @edit.post.body_markdown
    assert_equal @edit.tags_cache, @edit.post.tags_cache
    assert_equal @edit.title, @edit.post.title
  end

  test 'rejecting edit should change status' do
    sign_in users(:editor)

    post :reject, params: { id: suggested_edits(:pending_suggested_edit).id,
                            rejection_comment: 'WHY NOT?' }

    assert_response(:success)

    @edit = assigns(:edit)

    assert_not_nil @edit
    assert_equal @edit.active, false
    assert_equal @edit.accepted, false
    assert_equal @edit.before_body_markdown, @edit.post.body_markdown
    assert_equal @edit.before_tags_cache, @edit.post.tags_cache
    assert_equal @edit.before_title, @edit.post.title
    assert_equal @edit.rejected_comment, 'WHY NOT?'
  end
end
