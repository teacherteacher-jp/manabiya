Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check

  get    "/gate",                              to: "gate#index"
  get    "/auth/discord/callback",             to: "sessions#create"
  delete "/session",                           to: "sessions#destroy",
                                               as: "session"
  get    "/me",                                to: "me#index"
  get    "/schedules",                         to: "schedules#index"
  post   "/schedules",                         to: "schedules#create"
  get    "/schedules/:date/assignments",       to: "assignments#index",
                                               as: "schedule_assignments"
  post   "/schedules/:schedule_id/assignment", to: "assignments#create",
                                               as: "assignment"
  delete "/schedules/:schedule_id/assignment", to: "assignments#destroy"
  root   "root#index"
end
