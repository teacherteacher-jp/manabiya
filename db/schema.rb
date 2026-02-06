# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_06_131949) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "schedule_id", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_id"], name: "index_assignments_on_schedule_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "source_link", null: false
    t.datetime "start_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "venue", null: false
    t.index ["start_at"], name: "index_events_on_start_at"
  end

  create_table "family_members", force: :cascade do |t|
    t.date "birth_date"
    t.boolean "cohabiting", default: true, null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.bigint "member_id", null: false
    t.integer "relationship", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id", "cohabiting"], name: "index_family_members_on_member_id_and_cohabiting"
    t.index ["member_id"], name: "index_family_members_on_member_id"
  end

  create_table "guardianships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_guardianships_on_member_id"
    t.index ["student_id", "member_id"], name: "index_guardianships_on_student_id_and_member_id", unique: true
    t.index ["student_id"], name: "index_guardianships_on_student_id"
  end

  create_table "member_regions", force: :cascade do |t|
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.bigint "region_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_member_regions_on_member_id"
    t.index ["region_id"], name: "index_member_regions_on_region_id"
  end

  create_table "members", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "discord_uid", limit: 32, null: false
    t.string "icon_url", limit: 2083, null: false
    t.string "name", limit: 32, null: false
    t.datetime "server_joined_at"
    t.datetime "updated_at", null: false
    t.index ["discord_uid"], name: "index_members_on_discord_uid", unique: true
    t.index ["server_joined_at"], name: "index_members_on_server_joined_at"
  end

  create_table "metalife_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "floor_id"
    t.text "message"
    t.bigint "metalife_user_id"
    t.datetime "occurred_at", null: false
    t.jsonb "payload"
    t.string "space_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type", "occurred_at"], name: "index_metalife_events_on_event_type_and_occurred_at"
    t.index ["metalife_user_id", "occurred_at"], name: "index_metalife_events_on_metalife_user_id_and_occurred_at"
    t.index ["metalife_user_id"], name: "index_metalife_events_on_metalife_user_id"
    t.index ["occurred_at"], name: "index_metalife_events_on_occurred_at"
    t.index ["space_id"], name: "index_metalife_events_on_space_id"
  end

  create_table "metalife_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "linkable_id"
    t.string "linkable_type"
    t.string "metalife_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["linkable_type", "linkable_id"], name: "index_metalife_users_on_linkable"
    t.index ["metalife_id"], name: "index_metalife_users_on_metalife_id", unique: true
  end

  create_table "regions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_regions_on_code", unique: true
    t.index ["name"], name: "index_regions_on_name"
  end

  create_table "schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "member_id", null: false
    t.string "memo", limit: 255
    t.integer "slot", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_schedules_on_date"
    t.index ["member_id", "date", "slot"], name: "index_schedules_on_member_id_and_date_and_slot", unique: true
    t.index ["member_id"], name: "index_schedules_on_member_id"
  end

  create_table "school_memo_students", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "school_memo_id", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["school_memo_id"], name: "index_school_memo_students_on_school_memo_id"
    t.index ["student_id"], name: "index_school_memo_students_on_student_id"
  end

  create_table "school_memos", force: :cascade do |t|
    t.integer "category", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_school_memos_on_member_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grade", null: false
    t.string "name", limit: 20, null: false
    t.integer "parent_member_id"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "assignments", "schedules"
  add_foreign_key "family_members", "members"
  add_foreign_key "guardianships", "members"
  add_foreign_key "guardianships", "students"
  add_foreign_key "member_regions", "members"
  add_foreign_key "member_regions", "regions"
  add_foreign_key "metalife_events", "metalife_users"
  add_foreign_key "schedules", "members"
  add_foreign_key "school_memo_students", "school_memos"
  add_foreign_key "school_memo_students", "students"
  add_foreign_key "school_memos", "members"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "students", "members", column: "parent_member_id"
end
