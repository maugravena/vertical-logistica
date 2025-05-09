require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations' do
    let(:user) { User.create(user_id: '1234567890', name: 'Test User') }

    it 'is valid with valid attributes' do
      order = Order.new(order_id: '0987654321', purchase_date: Date.today, user: user)
      expect(order).to be_valid
    end

    it 'is not valid without an order_id' do
      order = Order.new(purchase_date: Date.today, user: user)
      expect(order).to_not be_valid
    end

    it 'is not valid without a purchase_date' do
      order = Order.new(order_id: '0987654321', user: user)
      expect(order).to_not be_valid
    end

    it 'is not valid without a user' do
        order = Order.new(order_id: '0987654321', purchase_date: Date.today)
        expect(order).to_not be_valid
      end
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many order_items' do
      association = described_class.reflect_on_association(:order_items)
      expect(association.macro).to eq :has_many
    end

    it 'has many products through order_items' do
      association = described_class.reflect_on_association(:products)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :order_items
    end
  end
end
