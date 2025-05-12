class AddValueToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :value, :decimal
  end
end
