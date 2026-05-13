class Dump < ApplicationRecord
  has_one_attached :file

  before_destroy :delete_file

  private

  def delete_file
    file.purge
  end
end
