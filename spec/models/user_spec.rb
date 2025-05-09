require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(user_id: '1234567890', name: 'Test User')
      expect(user).to be_valid
    end

    it 'is not valid without a user_id' do
      user = User.new(name: 'Test User')
      expect(user).to_not be_valid
    end

    it 'is not valid without a name' do
      user = User.new(user_id: '1234567890')
      expect(user).to_not be_valid
    end
  end

  describe 'associations' do
    it 'has many orders' do
      association = described_class.reflect_on_association(:orders)
      expect(association.macro).to eq :has_many
    end
  end
end
