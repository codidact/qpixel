require 'test_helper'

module Maintenance
  class FixRejectedEditStatesTaskTest < ActiveSupport::TestCase
    test 'perform should correctly fix rejected edit states' do
      edit = suggested_edits(:rejected_suggested_edit)

      Maintenance::FixRejectedEditStatesTask.process(edit)
      edit.reload

      assert_not_nil edit.before_body
      assert_not_nil edit.before_body_markdown
      assert_not_nil edit.before_title
    end
  end
end
