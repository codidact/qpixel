class Reaction < ApplicationRecord
  belongs_to :reaction_type, foreign_key: :reaction_types_id
  belongs_to :user, foreign_key: :users_id
  belongs_to :post, foreign_key: :posts_id
  belongs_to :comment, foreign_key: :comments_id
end
