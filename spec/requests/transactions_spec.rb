require 'rails_helper'

RSpec.describe '/transactions', type: :request do
  describe 'GET /transactions' do
    let!(:user1) { User.create!(user_id: 1, name: 'Zarelli') }
    let!(:user2) { User.create!(user_id: 2, name: 'Medeiros') }

    let!(:order1) { Order.create!(order_id: 123, user: user1, purchase_date: '2021-12-01') }
    let!(:order2) { Order.create!(order_id: 12345, user: user2, purchase_date: '2020-12-01') }

    let!(:product1) { Product.create!(product_id: 111, value: 512.24) }
    let!(:product2) { Product.create!(product_id: 122, value: 512.24) }

    let!(:order_item1) { OrderItem.create!(order: order1, product: product1, value: 512.24) }
    let!(:order_item2) { OrderItem.create!(order: order1, product: product2, value: 512.24) }
    let!(:order_item3) { OrderItem.create!(order: order2, product: product1, value: 256.24) }
    let!(:order_item4) { OrderItem.create!(order: order2, product: product2, value: 256.24) }

    it 'returns all orders without filters' do
      get '/transactions'

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([
        {
          'user_id' => 1,
          'name' => 'Zarelli',
          'orders' => [
            {
              'order_id' => 123,
              'total' => '1024.48',
              'date' => '2021-12-01',
              'products' => [
                { 'product_id' => 111, 'value' => '512.24' },
                { 'product_id' => 122, 'value' => '512.24' }
              ]
            }
          ]
        },
        {
          'user_id' => 2,
          'name' => 'Medeiros',
          'orders' => [
            {
              'order_id' => 12345,
              'total' => '512.48',
              'date' => '2020-12-01',
              'products' => [
                { 'product_id' => 111, 'value' => '256.24' },
                { 'product_id' => 122, 'value' => '256.24' }
              ]
            }
          ]
        }
      ])
    end

    it 'filters by order_id' do
      get '/transactions', params: { order_id: 123 }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([
        {
          'user_id' => 1,
          'name' => 'Zarelli',
          'orders' => [
            {
              'order_id' => 123,
              'total' => '1024.48',
              'date' => '2021-12-01',
              'products' => [
                { 'product_id' => 111, 'value' => '512.24' },
                { 'product_id' => 122, 'value' => '512.24' }
              ]
            }
          ]
        }
      ])
    end

    it 'filters by date range' do
      get '/transactions', params: { start_date: '2021-01-01', end_date: '2021-12-31' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([
        {
          'user_id' => 1,
          'name' => 'Zarelli',
          'orders' => [
            {
              'order_id' => 123,
              'total' => '1024.48',
              'date' => '2021-12-01',
              'products' => [
                { 'product_id' => 111, 'value' => '512.24' },
                { 'product_id' => 122, 'value' => '512.24' }
              ]
            }
          ]
        }
      ])
    end
  end

  describe 'error handling' do
    it 'returns an error for invalid date format' do
      get '/transactions', params: { start_date: 'invalid-date', end_date: '2021-12-31' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid date' })
    end

    it 'returns an error for start_date greater than end_date' do
      get '/transactions', params: { start_date: '2022-01-01', end_date: '2021-12-31' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'start_date cannot be greater than end_date.' })
    end

    it 'returns not found for no matching transactions' do
      get '/transactions', params: { start_date: '2000-01-01', end_date: '2000-12-31' }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'No transactions found for the given filters' })
    end

    it 'handles unexpected errors gracefully' do
      allow(Order).to receive(:includes).and_raise(StandardError, 'Unexpected error')

      get '/transactions'

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'An unexpected error occurred' })
    end
  end
end
