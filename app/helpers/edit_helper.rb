module EditHelper
  ##
  # Get the maximum edit comment length for the current community, with a maximum of 255.
  # @return [Integer]
  def max_edit_comment_length
    [SiteSetting['MaxEditCommentLength'] || 255, 255].min
  end
end
