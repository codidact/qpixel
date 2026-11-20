module Lockable
  extend ActiveSupport::Concern

  included do
    belongs_to :locked_by, class_name: 'User', optional: true

    scope :locked, -> { where(locked: true) }
    scope :not_locked, -> { where(locked: false) }
  end

  # Checks whether the record has a lock & that it's not expired
  def lock_active?
    locked && (locked_until.nil? || !locked_until.past?)
  end

  # TODO: predicate methods should not have side-effects! This is for backwards compatibility only
  def locked?
    return true if lock_active?

    if locked
      update(locked: false, locked_by: nil, locked_at: nil, locked_until: nil)
    end

    false
  end
end
