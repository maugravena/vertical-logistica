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
    data.split("\n").map do |line|
      next if line.strip.empty?

      {
        user: {
          user_id: line[0..9].strip,
          name: line[10..54].strip
        },
        order: {
          order_id: line[55..64].strip,
          purchase_date: line[87..94]
        },
        product: {
          product_id: line[65..74].strip,
          value: line[75..86].strip.to_f
        }
      }
    end.compact
  end
end
