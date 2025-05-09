class User < ApplicationRecord
  has_many :orders

  validates :user_id, :name, presence: true
end
