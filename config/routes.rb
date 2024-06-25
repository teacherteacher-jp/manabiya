Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check

  get    "/auth/discord/callback", to: "sessions#create"
  delete "/session",               to: "sessions#destroy"
  root   "root#index"
end
