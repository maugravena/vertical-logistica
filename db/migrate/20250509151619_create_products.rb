class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :product_id
      t.decimal :product_value

      t.timestamps
    end
  end
end
