class Product < ApplicationRecord
  has_many :order_items
  has_many :orders, through: :order_items

  validates :product_id, :product_value, presence: true
end
