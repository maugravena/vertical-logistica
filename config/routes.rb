Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "/imports/transactions", to: "imports#transactions"

  get "/transactions", to: "transactions#index"
end
