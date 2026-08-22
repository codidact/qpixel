module AdminHelper
  # Renders related model for a given log
  # @param log [AuditLog] log to render related model for
  # @return [String] rendered related model
  def rendered_related(log)
    return '' unless log.related.present?

    if log.related.is_a?(User)
      return user_link(log.related)
    end

    base = "#{log.related_type} ##{log.related_id}"

    if log.related.respond_to?(:name)
      "#{base} (#{log.related.name})"
    else
      base
    end
  end
end
