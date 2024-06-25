Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check

  get    "/gate",                  to: "gate#index"
  get    "/auth/discord/callback", to: "sessions#create"
  delete "/session",               to: "sessions#destroy",  as: "session"
  get    "/schedules",             to: "schedules#index"
  post   "/schedules",             to: "schedules#create"
  patch  "/schedules",             to: "schedules#update"
  root   "root#index"
end
