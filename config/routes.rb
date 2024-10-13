Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check

  get    "/gate",                              to: "gate#index"
  get    "/auth/discord/callback",             to: "sessions#create"
  delete "/session",                           to: "sessions#destroy",
                                               as: "session"
  get    "/schedules",                         to: "schedules#index"
  post   "/schedules",                         to: "schedules#create"
  get    "/schedules/:date/assignments",       to: "assignments#index",
                                               as: "schedule_assignments"
  post   "/schedules/:schedule_id/assignment", to: "assignments#create",
                                               as: "assignment"
  delete "/schedules/:schedule_id/assignment", to: "assignments#destroy"
  post   "/schedules/:date/notification",      to: "notifications#create",
                                               as: "notification"
  get    "/regions",                           to: "regions#index"
  post   "/member_regions",                    to: "member_regions#create"
  delete "/member_regions/:member_region_id",  to: "member_regions#destroy",
                                               as: "member_region"
  post   "/family_members",                    to: "family_members#create"
  delete "/family_members/:family_member_id",  to: "family_members#destroy",
                                               as: "family_member"
  get    "/members/:member_id",                to: "members#show",
                                               as: "member"
  get    "/generations",                       to: "generations#index"
  get    "/my/schedules",                      to: "my/schedules#index"
  get    "/my/regions",                        to: "my/regions#index"
  get    "/my/family_members",                 to: "my/family_members#index"
  post   "/webhooks/metalife",                 to: "webhooks/metalife#create"

  root   "root#index"
end
