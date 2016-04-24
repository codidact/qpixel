class AddUserToQuestions < ActiveRecord::Migration
  def change
    add_reference :questions, :user, index: true, foreign_key: true
  end
end
