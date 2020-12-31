class CommentThread < ApplicationRecord
    include PostRelated

    has_many :comments
    belongs_to :locked_by, class_name: 'User', optional: true
    belongs_to :archived_by, class_name: 'User', optional: true
    belongs_to :deleted_by, class_name: 'User', optional: true

    scope :undeleted, -> { where(deleted: false) }
    scope :publicly_available, -> { where(deleted: false, archived: false) }
end
