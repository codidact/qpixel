require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should correctly rename thread' do
    sign_in users(:deleter)

    try_rename_thread(comment_threads(:normal))

    assert_response(:found)
    assert_not_nil assigns(:comment_thread)
    assert_redirected_to comment_thread_path(assigns(:comment_thread))
    assert_equal 'new thread title', assigns(:comment_thread).title
  end

  test 'non-moderators should not be able to rename restricted threads' do
    sign_in users(:deleter)

    [:locked, :archived, :deleted].each do |name|
      before_title = comment_threads(name).title

      try_rename_thread(comment_threads(name))

      @thread = assigns(:comment_thread)

      assert_response(:found)
      assert_not_nil @thread
      assert_redirected_to comment_thread_path(@thread)
      assert_equal before_title, @thread.title
    end
  end
end
