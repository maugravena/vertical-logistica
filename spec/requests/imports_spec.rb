require 'rails_helper'

RSpec.describe '/imports', type: :request do
  describe 'POST /imports/transactions' do
    let(:payload) do
      File.read(Rails.root.join('spec', 'fixtures', 'payloads', 'data_1.txt'))
    end
    let(:sample_payload) do
      File.read(Rails.root.join('spec', 'fixtures', 'payloads', 'small_sample_data.txt'))
    end

    context 'when payload data is present' do
      it 'returns success HTTP 200 :ok with a success message' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': payload }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Data imported successfully' })
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

    context 'when payload data is missing' do
      it 'returns HTTP 422 :unprocessable_entity with an error message' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': '' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'No data provided' })
      end
    end

    context 'when a parsing error occurs' do
      before do
        allow(Transaction::Parser).to receive(:call).and_raise(Transaction::Parser::ParseError, 'Invalid format')
      end

      it 'returns HTTP 422 :unprocessable_entity with a parsing error message' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': payload }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Parsing error: Invalid format' })
      end
    end

    context 'when the payload contains invalid data' do
      let(:invalid_payload) { "INVALID DATA" }

      it 'returns HTTP 422 :unprocessable_entity with a parsing error message' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE' => 'text/plain' }, env: { 'RAW_POST_DATA' => invalid_payload }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => "Parsing error: Invalid data format: undefined method 'strip' for nil" })
      end
    end

    context 'when a database error occurs' do
      before do
        allow(Transaction::Persistence).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(User.new))
      end

      it 'returns HTTP 422 :unprocessable_entity with a database error message' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': payload }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('Database error:')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(Transaction::Persistence).to receive(:call).and_raise(StandardError, 'Something went wrong')
      end

      it 'returns HTTP 500 :internal_server_error with an unexpected error message' do
        post '/imports/transactions', headers: { 'CONTENT_TYPE': 'text/plain' }, env: { 'RAW_POST_DATA': payload }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Unexpected error: Something went wrong' })
      end
    end
  end
end
