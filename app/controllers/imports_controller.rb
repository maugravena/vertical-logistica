class ImportsController < ApplicationController
  def transactions
    if request.raw_post.blank?
      render json: { error: "Dados não fornecidos" }, status: :unprocessable_entity
      return
    end

    parsed_data = TransactionParser.call(request.raw_post)

    ActiveRecord::Base.transaction do
      parsed_data.each do |user_data|
        user = User.find_or_create_by!(
          user_id: user_data[:user_id],
          name: user_data[:name]
        )

        user_data[:orders].each do |order_data|
          order = Order.create!(
            order_id: order_data[:order_id],
            user: user,
            purchase_date: Date.parse(order_data[:date])
          )

          order_data[:products].each do |product_data|
            product = Product.find_or_create_by!(product_id: product_data[:product_id])

            OrderItem.create!(
              order: order,
              product: product,
              value: product_data[:value].to_f
            )
          end
        end
      end
    end

    saved_data = User.includes(orders: { order_items: :product })
                    .where(user_id: parsed_data.map { |d| d[:user_id] })
                    .map do |user|
      {
        user_id: user.user_id.to_i,
        name: user.name,
        orders: user.orders.order(:order_id).map do |order|
          {
            order_id: order.order_id.to_i,
            date: order.purchase_date.iso8601,
            total: format_decimal(order.order_items.sum(&:value)),
            products: order.order_items.joins(:product)
                         .order("products.product_id")
                         .map do |item|
              {
                product_id: item.product.product_id.to_i,
                value: format_decimal(item.value)
              }
            end
          }
        end
      }
    end

    render json: saved_data, status: :ok
  end

  private

  def format_decimal(value)
    "%.2f" % value.to_f
  end
end
