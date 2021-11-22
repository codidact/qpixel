class MicroAuth::App < ApplicationRecord
  has_many :tokens, :class_name => 'MicroAuth::Token'
  has_many :users, through: :tokens
  belongs_to :user
  belongs_to :deactivated_by, class_name: 'User', required: false

  validates :app_id, presence: true, uniqueness: true
  validates :secret_key, presence: true, uniqueness: true
  validates :public_key, presence: true, uniqueness: true
end
