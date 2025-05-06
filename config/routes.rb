Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get    "/gate",                                  to: "gate#index"
  get    "/auth/discord/callback",                 to: "sessions#create"
  delete "/session",                               to: "sessions#destroy",
                                                   as: "session"

  get    "/schedules",                             to: "schedules#index"
  post   "/schedules",                             to: "schedules#create"
  get    "/schedules/:date/assignments",           to: "assignments#index",
                                                   as: "schedule_assignments"
  post   "/schedules/:schedule_id/assignment",     to: "assignments#create",
                                                   as: "assignment"
  delete "/schedules/:schedule_id/assignment",     to: "assignments#destroy"
  post   "/schedules/:date/notification",          to: "notifications#create",
                                                   as: "notification"
  get    "/students",                              to: "students#index",
                                                   as: "students"
  get    "/students/new",                          to: "students#new",
                                                   as: "new_student"
  get    "/students/:id",                          to: "students#show",
                                                   as: "student"
  get    "/students/:id/edit",                     to: "students#edit",
                                                   as: "edit_student"
  patch  "/students/:id",                          to: "students#update"
  post   "/students",                              to: "students#create"
  post   "/students/:student_id/memos",            to: "student_memos#create",
                                                   as: "student_memos"
  get    "/student_memos/:id/edit",                to: "student_memos#edit",
                                                   as: "edit_student_memo"
  patch  "/student_memos/:id",                     to: "student_memos#update",
                                                   as: "student_memo"
  delete "/student_memos/:id",                     to: "student_memos#destroy"

  get    "/regions",                               to: "regions#index"
  post   "/member_regions",                        to: "member_regions#create"
  delete "/member_regions/:member_region_id",      to: "member_regions#destroy",
                                                   as: "member_region"
  post   "/family_members",                        to: "family_members#create"
  delete "/family_members/:family_member_id",      to: "family_members#destroy",
                                                   as: "family_member"
  get    "/family_members/:family_member_id/edit", to: "family_members#edit",
                                                   as: "edit_family_member"
  patch  "/family_members/:family_member_id",      to: "family_members#update"
  get    "/members/:member_id",                    to: "members#show",
                                                   as: "member"
  get    "/generations",                           to: "generations#index"
  get    "/my/schedules",                          to: "my/schedules#index"
  get    "/my/regions",                            to: "my/regions#index"
  get    "/my/family_members",                     to: "my/family_members#index"
  get    "/events",                                to: "events#index"
  get    "/events/new",                            to: "events#new",
                                                   as: "new_event"
  post   "/events",                                to: "events#create"
  get    "/events/:id",                            to: "events#show",
                                                   as: "event",
                                                   constraints: { id: /\d+/ }
  get    "/events/:id/edit",                       to: "events#edit",
                                                   as: "edit_event"
  patch  "/events/:id",                            to: "events#update"
  get    "/events/in_past",                        to: "events/in_past#index"
  get    "/public/events.ics",                     to: "public/events#index",
                                                   as: "public_events"
  post   "/webhooks/metalife",                     to: "webhooks/metalife#create"
  post   "/webhooks/line",                         to: "webhooks/line#create"

  root   "root#index"
end
