class ImportsController < ApplicationController
  def transactions
    if params[:data].blank?
      render json: { error: "Dados não fornecidos" }, status: :unprocessable_entity
      return
    end

    parsed_data = parse_transactions(params[:data])
    render json: { data: parsed_data }, status: :ok
  end

  private

  def parse_transactions(data)
    transactions = data.split("\n").map do |line|
      next if line.strip.empty?

      {
        user_id: line[0..9].strip,
        name: line[10..54].strip,
        order_id: line[55..64].strip,
        product_id: line[65..74].strip,
        value: line[75..86].strip,
        purchase_date: line[87..94]
      }
    end.compact

    transactions.group_by { |t| t[:user_id] }.map do |user_id, user_transactions|
      {
        user_id: user_id.to_i,
        name: user_transactions.first[:name],
        orders: user_transactions.group_by { |t| t[:order_id] }.map do |order_id, order_transactions|
          {
            order_id: order_id.to_i,
            date: format_date(order_transactions.first[:purchase_date]),
            total: format_decimal(order_transactions.sum { |t| t[:value].to_f }),
            products: order_transactions.map do |t|
              {
                product_id: t[:product_id].to_i,
                value: format_decimal(t[:value])
              }
            end
          }
        end
      }
    end
  end

  def format_date(date_str)
    Date.strptime(date_str, "%Y%m%d").iso8601
  end

  def format_decimal(value)
    "%.2f" % value
  end
end
