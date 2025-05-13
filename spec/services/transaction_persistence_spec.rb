require 'rails_helper'

RSpec.describe TransactionPersistence, type: :service do
  describe '.call' do
    let(:parsed_data) do
      [ {
        user_id: 200,
        name: 'John Smith',
        orders: [
          {
            order_id: 101,
            date: '2021-05-01',
            total: '650.00',
            products: [
              { product_id: 1, value: '150.00' },
              { product_id: 2, value: '200.00' },
              { product_id: 3, value: '300.00' }
            ]
          },
          {
            order_id: 102,
            date: '2021-05-02',
            total: '600.00',
            products: [
              { product_id: 4, value: '100.00' },
              { product_id: 5, value: '200.00' },
              { product_id: 6, value: '300.00' }
            ]
          }
        ]
      } ]
    end

    it 'creates all records correctly' do
      expect {
        described_class.call(parsed_data)
      }.to change(User, :count).by(1)
        .and change(Order, :count).by(2)
        .and change(Product, :count).by(6)
        .and change(OrderItem, :count).by(6)

      user = User.last
      expect(user.user_id).to eq(200)
      expect(user.name).to eq('John Smith')

      orders = user.orders.order(:order_id)
      expect(orders.count).to eq(2)

      first_order = orders.first
      expect(first_order.order_id).to eq(101)
      expect(first_order.purchase_date).to eq(Date.parse('2021-05-01'))

      second_order = orders.last
      expect(second_order.order_id).to eq(102)
      expect(second_order.purchase_date).to eq(Date.parse('2021-05-02'))

      first_order_items = first_order.order_items.includes(:product).order('products.product_id')
      expect(first_order_items.map { |item| item.product.product_id }).to eq([ 1, 2, 3 ])
      expect(first_order_items.map { |item| item.value.to_s }).to eq([ '150.0', '200.0', '300.0' ])

      second_order_items = second_order.order_items.includes(:product).order('products.product_id')
      expect(second_order_items.map { |item| item.product.product_id }).to eq([ 4, 5, 6 ])
      expect(second_order_items.map { |item| item.value.to_s }).to eq([ '100.0', '200.0', '300.0' ])
    end

    context 'when user already exists' do
      before do
        User.create!(user_id: 200, name: 'John Smith')
      end

      it 'reuses existing user' do
        expect {
          described_class.call(parsed_data)
        }.not_to change(User, :count)
      end
    end

    context 'when product already exists' do
      before do
        Product.create!(product_id: 1)
      end

      it 'reuses existing product' do
        expect {
          described_class.call(parsed_data)
        }.to change(Product, :count).by(5)
      end
    end

    context 'with invalid data' do
      let(:invalid_data) do
        [ {
          user_id: 200,
          name: 'John Smith',
          orders: [ {
            order_id: 101,
            date: 'invalid-date',
            products: [ { product_id: 1, value: '150.00' } ]
          } ]
        } ]
      end

      it 'raises an error and rolls back the transaction' do
        expect {
          described_class.call(invalid_data)
        }.to raise_error(Date::Error)
          .and not_change(User, :count)
          .and not_change(Order, :count)
          .and not_change(Product, :count)
          .and not_change(OrderItem, :count)
      end
    end
  end
end
