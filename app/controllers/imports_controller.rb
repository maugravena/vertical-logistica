class ImportsController < ApplicationController
  def transactions
    if request.raw_post.blank?
      render json: { error: "Dados não fornecidos" }, status: :unprocessable_entity
      return
    end

    parsed_data = TransactionParser.call(request.raw_post)
    TransactionPersistence.call(parsed_data)

    saved_data = User.includes(orders: { order_items: :product })
                    .where(user_id: parsed_data.map { |d| d[:user_id] })
                    .map do |user|
      {
        user_id: user.user_id,
        name: user.name,
        orders: user.orders.order(:order_id).map do |order|
          {
            order_id: order.order_id,
            date: order.purchase_date.iso8601,
            total: format_decimal(order.order_items.sum(&:value)),
            products: order.order_items.joins(:product)
                         .order("products.product_id")
                         .map do |item|
              {
                product_id: item.product.product_id,
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
