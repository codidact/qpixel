class AddPostingTipsOverridesToCategory < ActiveRecord::Migration[5.2]
  def change
    change_table :categories do |t|
      t.text :asking_guidance_override
      t.text :answering_guidance_override
    end
  end
end
