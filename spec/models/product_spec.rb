require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      product = Product.new(product_id: '1122334455', product_value: 10.50)
      expect(product).to be_valid
    end

    it 'is not valid without a product_id' do
      product = Product.new(product_value: 10.50)
      expect(product).to_not be_valid
    end

    it 'is not valid without a product_value' do
      product = Product.new(product_id: '1122334455')
      expect(product).to_not be_valid
    end
  end

  describe 'associations' do
    it 'has many order_items' do
      association = described_class.reflect_on_association(:order_items)
      expect(association.macro).to eq :has_many
    end

    it 'has many orders through order_items' do
        association = described_class.reflect_on_association(:orders)
        expect(association.macro).to eq :has_many
        expect(association.options[:through]).to eq :order_items
      end
  end
end
