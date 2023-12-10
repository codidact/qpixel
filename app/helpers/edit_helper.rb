module EditHelper
  def max_edit_comment_length
    [SiteSetting['MaxEditCommentLength'] || 255, 255].min
  end
end