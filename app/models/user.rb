class User < ApplicationRecord
  has_many :orders, dependent: :destroy

  validates :user_id, :name, presence: true
end
