class ImportsController < ApplicationController
  def transactions
    if request.raw_post.blank?
      render json: { error: "Dados não fornecidos" }, status: :unprocessable_entity
      return
    end

    parsed_data = parse_transactions(request.raw_post)

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

  def parse_transactions(data)
    transactions = data.split("\n").map do |line|
      next if line.strip.empty?

      {
        user_id: line[0..9].strip.to_i,
        name: line[10..54].strip,
        order_id: line[55..64].strip.to_i,
        product_id: line[65..74].strip.to_i,
        value: line[75..86].strip,
        purchase_date: line[87..94].strip
      }
    end.compact

    transactions.group_by { |t| t[:user_id] }.map do |user_id, user_transactions|
      {
        user_id: user_id,
        name: user_transactions.first[:name],
        orders: user_transactions.group_by { |t| t[:order_id] }.map do |order_id, order_transactions|
          {
            order_id: order_id,
            date: format_date(order_transactions.first[:purchase_date]),
            total: format_decimal(order_transactions.sum { |t| t[:value].to_f }),
            products: order_transactions.sort_by { |t| t[:product_id] }.map do |t|
              {
                product_id: t[:product_id],
                value: format_decimal(t[:value])
              }
            end
          }
        end.sort_by { |order| order[:order_id] }
      }
    end.sort_by { |user| user[:user_id] }
  end

  def format_date(date_str)
    Date.strptime(date_str, "%Y%m%d").iso8601
  end

  def format_decimal(value)
    "%.2f" % value.to_f
  end
end
