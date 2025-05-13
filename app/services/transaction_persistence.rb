class TransactionPersistence
  def self.call(parsed_data)
    new(parsed_data).call
  end

  def initialize(parsed_data)
    @parsed_data = parsed_data
  end

  def call
    ActiveRecord::Base.transaction do
      @parsed_data.each do |user_data|
        user = create_or_find_user(user_data)
        create_orders(user, user_data[:orders])
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
    products_data.each do |product_data|
      product = Product.find_or_create_by!(product_id: product_data[:product_id])
      OrderItem.create!(
        order: order,
        product: product,
        value: product_data[:value].to_f
      )
    end
  end
end
