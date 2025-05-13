class TransactionParser
  class ParseError < StandardError; end

  FIELD_POSITIONS = {
    user_id: 0..9,
    name: 10..54,
    order_id: 55..64,
    product_id: 65..74,
    value: 75..86,
    purchase_date: 87..94
  }.freeze

  def self.call(data)
    new(data).call
  end

  def initialize(data)
    @data = data
  end

  def call
    raw_transactions = parse_lines

    group_transactions(raw_transactions)
  end

  private

  def parse_lines
    @data.split("\n").map do |line|
      next if line.strip.empty?

      begin
        {
          user_id: line[FIELD_POSITIONS[:user_id]].strip.to_i,
          name: line[FIELD_POSITIONS[:name]].strip,
          order_id: line[FIELD_POSITIONS[:order_id]].strip.to_i,
          product_id: line[FIELD_POSITIONS[:product_id]].strip.to_i,
          value: line[FIELD_POSITIONS[:value]].strip,
          purchase_date: line[FIELD_POSITIONS[:purchase_date]].strip
        }
      rescue StandardError => e
        raise ParseError, "Invalid data format: #{e.message}"
      end
    end.compact
  end

  def group_transactions(transactions)
    raise ParseError, "Invalid transactions data" if transactions.nil? || !transactions.is_a?(Array)

    transactions.group_by { |t| t[:user_id] }.map do |user_id, user_transactions|
      {
        user_id: user_id,
        name: user_transactions.first[:name],
        orders: group_orders(user_transactions)
      }
    end.sort_by { |user| user[:user_id] }
  end

  def group_orders(user_transactions)
    raise ParseError, "Invalid user transactions data" if user_transactions.nil? || !user_transactions.is_a?(Array)

    user_transactions.group_by { |t| t[:order_id] }.map do |order_id, order_transactions|
      {
        order_id: order_id,
        date: format_date(order_transactions.first[:purchase_date]),
        total: format_decimal(order_transactions.sum { |t| t[:value].to_f }),
        products: group_products(order_transactions)
      }
    end.sort_by { |order| order[:order_id] }
  end

  def group_products(order_transactions)
    raise ParseError, "Invalid order transactions data" if order_transactions.nil? || !order_transactions.is_a?(Array)

    order_transactions.sort_by { |t| t[:product_id] }.map do |t|
      {
        product_id: t[:product_id],
        value: format_decimal(t[:value])
      }
    end
  end

  def format_date(date_string)
    Date.strptime(date_string, "%Y%m%d").iso8601
  rescue Date::Error
    raise ParseError, "Invalid date format: #{date_string}"
  end

  def format_decimal(value)
    "%.2f" % value.to_f
  end
end
