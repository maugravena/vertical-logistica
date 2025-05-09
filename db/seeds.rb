users = 10.times.map do |n|
  User.create!(
    user_id: "#{ (n + 1).to_s.rjust(10, '0') }",
    name: "User #{n + 1}"
  )
end

products = 10.times.map do |n|
  Product.create!(
    product_id: "#{ (n + 1).to_s.rjust(10, '0') }",
    product_value: (n + 1) * 10.50
  )
end

10.times do |n|
  user = users[n % users.size]
  order = Order.create!(
    user: user,
    order_id: "#{ (n + 1).to_s.rjust(10, '0') }",
    purchase_date: Date.today - n.days
  )

  number_of_items = rand(2..5)
  number_of_items.times do |i|
    product = products[(n + i) % products.size]
    OrderItem.create!(
      order: order,
      product: product
    )
  end
end

puts ":: Database Seeded! ::"
