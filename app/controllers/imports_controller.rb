class ImportsController < ApplicationController
  def transactions
    if request.raw_post.blank?
      render json: { error: "No data provided" }, status: :unprocessable_entity
      return
    end

    parsed_data = TransactionParser.call(request.raw_post)
    TransactionPersistence.call(parsed_data)

    render json: { message: "Data imported successfully" }, status: :ok
  rescue TransactionParser::ParseError => e
    render json: { error: "Parsing error: #{e.message}" }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Database error: #{e.record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: "Unexpected error: #{e.message}" }, status: :internal_server_error
  end
end
