module DraftManagement
  extend ActiveSupport::Concern

  DRAFTABLE_FIELDS = [:body, :comment, :excerpt, :license, :saved_at, :tags, :tag_name, :title].freeze
  NESTED_DRAFTABLE_FIELDS = [:body, :saved_at].freeze
  TOP_LEVEL_DRAFTABLE_FIELDS = [:body, :comment, :excerpt, :license, :tag_name, :tags, :title].freeze
  DRAFT_MAX_AGE = 86_400 * 7

  # saving by-field is kept for backwards compatibility with old drafts
  # @param user [User] user to save the draft for
  # @param path [String] draft path to save
  # @return [String] top level field key
  def do_save_draft(user, path)
    base_key = "saved_post.#{user.id}.#{path}"

    TOP_LEVEL_DRAFTABLE_FIELDS.each do |key|
      next unless params.key?(key)

      key_name = NESTED_DRAFTABLE_FIELDS.include?(key) ? base_key : "#{base_key}.#{key}"

      if key == :tags
        valid_tags = params[key]&.select(&:present?)

        RequestContext.redis.del(key_name)

        if valid_tags.present?
          RequestContext.redis.sadd(key_name, valid_tags)
        end
      else
        RequestContext.redis.set(key_name, params[key])
      end

      RequestContext.redis.expire(key_name, DRAFT_MAX_AGE)
    end

    saved_at_key = "saved_post_at.#{user.id}.#{path}"
    RequestContext.redis.set(saved_at_key, DateTime.now.iso8601)
    RequestContext.redis.expire(saved_at_key, DRAFT_MAX_AGE)

    base_key
  end

  # Attempts to delete a draft for a given path
  # @param user [User] user to delete the draft for
  # @param path [String] draft path to delete
  # @return [Boolean] status of the operation
  def do_delete_draft(user, path)
    keys = DRAFTABLE_FIELDS.map do |key|
      pfx = key == :saved_at ? 'saved_post_at' : 'saved_post'
      base = "#{pfx}.#{user.id}.#{path}"
      NESTED_DRAFTABLE_FIELDS.include?(key) ? base : "#{base}.#{key}"
    end

    RequestContext.redis.del(*keys)
  end
end
