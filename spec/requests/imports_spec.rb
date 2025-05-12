require 'rails_helper'

RSpec.describe '/imports', type: :request do
  describe 'POST /imports/transactions' do
    let(:payload) do
      File.read(Rails.root.join('spec', 'fixtures', 'payloads', 'data_1.txt'))
    end

    context 'when payload data is present' do
      it 'returns success HTTP 200 :ok' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': payload }

        expect(response).to have_http_status(:ok)
      end

      it 'parses multiple orders and products for the same user correctly' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': payload }

        parsed_response = JSON.parse(response.body)
        john_smith_data = parsed_response.find { |user| user['user_id'] == 200 }

        expect(john_smith_data).to eq(
          {
            'user_id' => 200,
            'name' => 'John Smith',
            'orders' => [
              {
                'order_id' => 101,
                'date' => '2021-05-01',
                'total' => '650.00',
                'products' => [
                  { 'product_id' => 1, 'value' => '150.00' },
                  { 'product_id' => 2, 'value' => '200.00' },
                  { 'product_id' => 3, 'value' => '300.00' }
                ]
              },
              {
                'order_id' => 102,
                'date' => '2021-05-02',
                'total' => '600.00',
                'products' => [
                  { 'product_id' => 4, 'value' => '100.00' },
                  { 'product_id' => 5, 'value' => '200.00' },
                  { 'product_id' => 6, 'value' => '300.00' }
                ]
              }
            ]
          }
        )
      end
    end

    context 'when using a small sample dataset' do
      let(:sample_payload) do
        File.read(Rails.root.join('spec', 'fixtures', 'payloads', 'small_sample_data.txt'))
      end

      it 'parses and groups all transactions correctly' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': sample_payload }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response).to contain_exactly({
          'user_id' => 1,
          'name' => 'Sammie Baumbach',
          'orders' => [
            {
              'order_id' => 14,
              'date' => '2021-09-08',
              'total' => '3037.44',
              'products' => [
                { 'product_id' => 3, 'value' => '1121.58' },
                { 'product_id' => 4, 'value' => '1915.86' }
              ]
            }
          ]
        },
        {
          'user_id' => 2,
          'name' => 'Augustus Aufderhar',
          'orders' => [
            {
              'order_id' => 21,
              'date' => '2021-12-12',
              'total' => '281.43',
              'products' => [
                { 'product_id' => 3, 'value' => '281.43' }
              ]
            }
          ]
        })
      end

      it 'saves the transactions data to the database' do
        expect {
          post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': sample_payload }
        }.to change(User, :count).by(2)
          .and change(Order, :count).by(2)
          .and change(Product, :count).by(2)
          .and change(OrderItem, :count).by(3)

        expect(response).to have_http_status(:ok)

        user = User.find_by(id: 1)
        expect(user.name).to eq('Sammie Baumbach')

        order = user.orders.first
        expect(order.id).to eq(1)
        expect(order.purchase_date).to eq(Date.new(2021, 9, 8))

        order_items = order.order_items.order(:product_id)
        expect(order_items.count).to eq(2)
        expect(order_items[0].product_id).to eq(1)
        expect(order_items[0].value).to eq(1121.58)
        expect(order_items[1].product_id).to eq(2)
        expect(order_items[1].value).to eq(1915.86)

        user = User.find_by(id: 2)
        expect(user.name).to eq('Augustus Aufderhar')

        order = user.orders.first
        expect(order.id).to eq(2)
        expect(order.purchase_date).to eq(Date.new(2021, 12, 12))

        order_item = order.order_items.first
        expect(order_item.product_id).to eq(1)
        expect(order_item.value).to eq(281.43)
      end
    end

    context 'when payload data is not presente' do
      it 'returns an error if data is not provided' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Dados não fornecidos' })
      end
    end
  end
end
