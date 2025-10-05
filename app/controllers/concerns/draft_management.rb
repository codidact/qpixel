module DraftManagement
  extend ActiveSupport::Concern

  DRAFTABLE_FIELDS = [:body, :comment, :excerpt, :license, :saved_at, :tags, :tag_name, :title].freeze

  # Attempts to delete a draft for a given path
  # @param path [String] draft path to delete
  # @return [Boolean] status of the operation
  def do_draft_delete(path)
    keys = DRAFTABLE_FIELDS.map do |key|
      pfx = key == :saved_at ? 'saved_post_at' : 'saved_post'
      base = "#{pfx}.#{current_user.id}.#{path}"
      [:body, :saved_at].include?(key) ? base : "#{base}.#{key}"
    end

    RequestContext.redis.del(*keys)
  end
end
