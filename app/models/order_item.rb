class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :value, presence: true, numericality: { greater_than: 0 }
end
