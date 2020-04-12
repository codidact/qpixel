class CorrectCloseReasonsReferenceAttributeName < ActiveRecord::Migration[5.2]
  def change
    rename_column :posts, :close_reasons_id, :close_reason_id
  end
end
