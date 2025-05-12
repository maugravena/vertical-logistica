class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.integer :product_id, null: false
      t.decimal :product_value, precision: 10, scale: 2

      t.timestamps
    end

    add_index :products, :product_id, unique: true
  end
end
