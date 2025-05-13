require 'rails_helper'

RSpec.describe TransactionParser, type: :service do
  describe '.parse' do
    context 'when given a valid transaction data' do
      let(:raw_data) do
        <<~TEXT
          0000000200                                   John Smith00000001010000000001      150.0020210501
          0000000200                                   John Smith00000001010000000002      200.0020210501
          0000000200                                   John Smith00000001010000000003      300.0020210501
          0000000200                                   John Smith00000001020000000004      100.0020210502
          0000000200                                   John Smith00000001020000000005      200.0020210502
          0000000200                                   John Smith00000001020000000006      300.0020210502
        TEXT
      end

      it 'parses and groups transactions by user' do
        result = described_class.call(raw_data)

        expect(result).to contain_exactly(
          {
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
          }
        )
      end
    end

    context 'when parsing multiple users' do
      let(:raw_data) do
        <<~TEXT
          0000000001                              Sammie Baumbach00000000140000000003     1121.5820210908
          0000000001                              Sammie Baumbach00000000140000000004     1915.8620210908
          0000000002                           Augustus Aufderhar00000000210000000003      281.4320211212
        TEXT
      end

      it 'correctly groups transactions for multiple users' do
        result = described_class.call(raw_data)

        expect(result).to contain_exactly(
          {
            user_id: 1,
            name: 'Sammie Baumbach',
            orders: [
              {
                order_id: 14,
                date: '2021-09-08',
                total: '3037.44',
                products: [
                  { product_id: 3, value: '1121.58' },
                  { product_id: 4, value: '1915.86' }
                ]
              }
            ]
          },
          {
            user_id: 2,
            name: 'Augustus Aufderhar',
            orders: [
              {
                order_id: 21,
                date: '2021-12-12',
                total: '281.43',
                products: [
                  { product_id: 3, value: '281.43' }
                ]
              }
            ]
          }
        )
      end
    end

    context 'when data contains empty lines' do
      let(:raw_data) do
        <<~TEXT

          0000000001                                    User One000000000100000000100      100.0020210501

          0000000001                                    User One000000000100000000200      200.0020210501

        TEXT
      end

      it 'ignores empty lines' do
        result = described_class.call(raw_data)

        expect(result.first[:orders].first[:products].count).to eq(2)
        expect(result.first[:orders].first[:total]).to eq('300.00')
      end
    end

    context 'with invalid data format' do
      context 'when date is invalid' do
        let(:raw_data) do
          "0000000001User One                                         0000000001000000001000100.00    20219999"
        end

        it 'raises an error for invalid date' do
          expect { described_class.call(raw_data) }.to raise_error(Date::Error)
        end
      end
    end
  end
end
