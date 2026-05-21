class Dump < ApplicationRecord
  has_one_attached :file

  before_destroy :delete_file

  scope :automatic, -> { where(automatic: true) }
  scope :manual, -> { where(automatic: false) }

  private

  def delete_file
    file.purge
  end
end
