class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :order_id, null: false
      t.date :purchase_date, null: false

      t.timestamps
    end
    
    add_index :orders, :order_id, unique: true
  end
end
