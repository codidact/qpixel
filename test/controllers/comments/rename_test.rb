require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly rename thread' do
    sign_in users(:deleter)

    try_rename_thread(comment_threads(:normal))
    @thread = assigns(:comment_thread)

    assert_response(:found)
    assert_not_nil(@thread)
    assert_redirected_to comment_thread_path(@thread)
    assert_equal 'new thread title', @thread.title
  end

  test 'non-moderators should not be able to rename restricted threads' do
    sign_in users(:deleter)

    [:locked, :archived, :deleted].each do |name|
      before_title = comment_threads(name).title

      try_rename_thread(comment_threads(name))
      @thread = assigns(:comment_thread)

      assert_response(:found)
      assert_not_nil(@thread)
      assert_redirected_to comment_thread_path(@thread)
      assert_equal before_title, @thread.title
    end
  end

  test 'should not allow renaming to the current title' do
    sign_in users(:admin)

    thread = comment_threads(:normal)

    try_rename_thread(thread, title: thread.title)
    @thread = assigns(:comment_thread)

    assert_response(:found)
    assert_not_nil(@thread)
    assert_equal flash[:danger], I18n.t('comments.errors.no_rename_thread_to_current_title')
    assert_equal thread.title, @thread.title
  end

  test 'should correctly handle invalid thread titles' do
    sign_in users(:admin)

    ['', 'a' * 512].each do |title|
      try_rename_thread(comment_threads(:normal), title: title)
      @thread = assigns(:comment_thread)

      assert_response(:found)
      assert_not_nil(@thread)
      assert_not @thread.valid?
      assert_not_nil flash[:danger]
    end
  end
end
