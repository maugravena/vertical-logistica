module Transaction
  class Persistence
    def self.call(parsed_data) = new(parsed_data).call

    def initialize(parsed_data)
      @parsed_data = parsed_data
    end

    def call
      ActiveRecord::Base.transaction do
        @parsed_data.each do |user_data|
          create_or_find_user(user_data)
            .then { |user| create_orders(user, user_data[:orders]) }
        end
      end
    end

    private

    def create_or_find_user(user_data)
      User.find_or_create_by!(
        user_id: user_data[:user_id],
        name: user_data[:name]
      )
    end

    def create_orders(user, orders_data)
      orders_data.each do |order_data|
        order = create_order(user, order_data)
        create_order_items(order, order_data[:products])
      end
    end

    def create_order(user, order_data)
      Order.create!(
        order_id: order_data[:order_id],
        user: user,
        purchase_date: Date.parse(order_data[:date])
      )
    end

    def create_order_items(order, products_data)
      existing_products = Product.where(product_id: products_data.pluck(:product_id)).index_by(&:product_id)

      new_products = products_data.reject { |p| existing_products.key?(p[:product_id]) }
      Product.insert_all(new_products.map { |p| { product_id: p[:product_id] } }) if new_products.any?

      all_products = Product.where(product_id: products_data.pluck(:product_id)).index_by(&:product_id)

      order_items = products_data.map do |product_data|
        {
          order_id: order.id,
          product_id: all_products[product_data[:product_id]].id,
          value: product_data[:value].to_f
        }
      end

      OrderItem.insert_all(order_items) if order_items.any?
    end
  end
end
