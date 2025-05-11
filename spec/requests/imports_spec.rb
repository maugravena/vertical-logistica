require 'rails_helper'

RSpec.describe '/imports', type: :request do
  describe 'POST /imports/transactions' do
    let(:payload) do
      File.read(Rails.root.join('spec', 'fixtures', 'payloads', 'data_1.txt'))
    end

    context 'when payload data is present' do
      it 'returns success HTTP 200 :ok' do
        post '/imports/transactions', params: { data: payload }

        expect(response).to have_http_status(:ok)
      end

      it 'parses the payload data correctly' do
        post '/imports/transactions', params: { data: payload }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['data']).to contain_exactly(
          {
            'user' => {
              'user_id' => '0000000070',
              'name' => 'Palmer Prosacco'
            },
            'order' => {
              'order_id' => '0000000753',
              'purchase_date' => '20210308'
            },
            'product' => {
              'product_id' => '0000000003',
              'value' => 1836.74
            }
          },
          {
            'user' => {
              'user_id' => '0000000075',
              'name' => 'Bobbie Batz'
            },
            'order' => {
              'order_id' => '0000000798',
              'purchase_date' => '20211116'
            },
            'product' => {
              'product_id' => '0000000002',
              'value' => 1578.57
            }
          },
          {
            'user' => {
              'user_id' => '0000000049',
              'name' => 'Ken Wintheiser'
            },
            'order' => {
              'order_id' => '0000000523',
              'purchase_date' => '20210903'
            },
            'product' => {
              'product_id' => '0000000003',
              'value' => 586.74
            }
          },
          {
            'user' => {
              'user_id' => '0000000014',
              'name' => 'Clelia Hills'
            },
            'order' => {
              'order_id' => '0000000146',
              'purchase_date' => '20211125'
            },
            'product' => {
              'product_id' => '0000000001',
              'value' => 673.49
            }
          }
        )
      end
    end

    context 'when payload data is not presente' do
      it 'returns an error if data is not provided' do
        post '/imports/transactions', params: {}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Dados não fornecidos' })
      end
    end
   end
end
