require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'legal delete should work' do
    sign_in users(:staff)
    try_legal_delete :question_one, 'fraud'
    assert_response(:found)
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal true, assigns(:post).deleted?
    assigns(:post).children.each do |child|
      assert_equal true, child.deleted?
    end
    histories = assigns(:post).post_histories
    histories.each_with_index do |history, index|
      if index == histories.size - 1
        assert_equal false, history.hidden?
      else
        assert_equal true, history.hidden?
      end
    end
    assert_not_nil assigns(:complaint)
    assert_empty assigns(:complaint).errors.full_messages
    assert_equal 'reviewed', assigns(:complaint).status
    assert_equal 'upheld', assigns(:complaint).outcome
  end

  private

  def try_legal_delete(post_sym, content_type)
    delete :legal_delete, params: { id: posts(post_sym).id, content_type: content_type }
  end
end
