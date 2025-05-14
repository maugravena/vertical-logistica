class RenameProductValueToValue < ActiveRecord::Migration[8.0]
  def change
    rename_column :products, :product_value, :value
  end
end
