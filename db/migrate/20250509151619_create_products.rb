class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :product_id
      t.decimal :product_value, precision: 10, scale: 2

      t.timestamps
    end
  end
end
