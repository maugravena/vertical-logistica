require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  describe 'validations' do
    let(:user) { User.create(user_id: '1234567890', name: 'Test User') }
    let(:order) { Order.create(order_id: '0987654321', purchase_date: Date.today, user: user) }
    let(:product) { Product.create(product_id: '1122334455') }

    it 'is valid with valid attributes' do
      order_item = OrderItem.new(order: order, product: product, value: 10.50)
      expect(order_item).to be_valid
    end

    it 'is not valid without an order' do
      order_item = OrderItem.new(product: product, value: 10.50)
      expect(order_item).to_not be_valid
    end

    it 'is not valid without a product' do
      order_item = OrderItem.new(order: order, value: 10.50)
      expect(order_item).to_not be_valid
    end

    it 'is not valid without a value' do
      order_item = OrderItem.new(order: order, product: product)
      expect(order_item).to_not be_valid
    end

    it 'is not valid with value less than or equal to zero' do
      order_item = OrderItem.new(order: order, product: product, value: 0)
      expect(order_item).to_not be_valid

      order_item.value = -1
      expect(order_item).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to an order' do
      association = described_class.reflect_on_association(:order)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to a product' do
      association = described_class.reflect_on_association(:product)
      expect(association.macro).to eq :belongs_to
    end
  end
end
