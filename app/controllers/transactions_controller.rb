class TransactionsController < ApplicationController
  def index
    validate_params!

    orders = Order.includes(:user, order_items: :product)
    orders = orders.where(order_id: params[:order_id]) if params[:order_id].present?

    if params[:start_date].present? && params[:end_date].present?
      orders = orders.where(purchase_date: params[:start_date]..params[:end_date])
    end

    if orders.empty?
      render json: { error: "No transactions found for the given filters" }, status: :not_found
      return
    end

    response = orders.group_by(&:user).map do |user, user_orders|
      {
        user_id: user.user_id,
        name: user.name,
        orders: user_orders.map do |order|
          {
            order_id: order.order_id,
            total: format_decimal(order.order_items.sum(&:value)),
            date: order.purchase_date.iso8601,
            products: order.order_items.map do |item|
              {
                product_id: item.product.product_id,
                value: format_decimal(item.value)
              }
            end
          }
        end
      }
    end

    render json: response, status: :ok
  rescue Date::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: "An unexpected error occurred" }, status: :internal_server_error
  end

  private

  def permited_params = params.permit(:order_id, :start_date, :end_date)

  def format_decimal(value) = "%.2f" % value.to_f

  def validate_params!
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])

      raise Date::Error, "start_date cannot be greater than end_date." if start_date > end_date
    end
  end
end
