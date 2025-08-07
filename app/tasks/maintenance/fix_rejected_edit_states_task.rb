# frozen_string_literal: true

module Maintenance
  class FixRejectedEditStatesTask < MaintenanceTasks::Task
    include ApplicationHelper

    def collection
      SuggestedEdit.rejected
    end

    def last_revision_before_decided(edit)
      PostHistory.of_type('post_edited')
                 .where(post: edit.post)
                 .where(created_at: edit.post.created_at..edit.decided_at)
                 .order(created_at: :desc)
                 .first
    end

    def initial_revision_before_decided(edit)
      PostHistory.of_type('initial_revision')
                 .where(post: edit.post)
                 .where(created_at: edit.post.created_at..edit.decided_at)
                 .order(created_at: :desc)
                 .first
    end

    def valid_before_attributes?(edit)
      [
        :before_body,
        :before_body_markdown,
        :before_tags_cache,
        :before_title
      ].all? do |attr|
        edit.send(attr).present?
      end
    end

    def process(edit)
      return if valid_before_attributes?(edit)

      last_revision = last_revision_before_decided(edit).presence || initial_revision_before_decided(edit)

      return unless last_revision.present?

      begin
        status = edit.update({ before_body: render_markdown(last_revision.after_state),
                               before_body_markdown: last_revision.after_state,
                               before_tags: last_revision.after_tags.dup,
                               before_tags_cache: last_revision.after_tags.map(&:name),
                               before_title: last_revision.after_title })

        unless status
          Rails.logger.warn("Failed to fix edit ##{edit.id}")
        end
      rescue StandardError => e
        Rails.logger.warn(e)
      end
    end
  end
end
