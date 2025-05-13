class ChangeIdsToInteger < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :user_id, :integer, using: 'user_id::integer'
    change_column :products, :product_id, :integer, using: 'product_id::integer'
    change_column :orders, :order_id, :integer, using: 'order_id::integer'
  end
end
