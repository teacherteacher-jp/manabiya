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

ActiveRecord::Schema[7.2].define(version: 2024_09_23_054720) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.bigint "schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_id"], name: "index_assignments_on_schedule_id", unique: true
  end

  create_table "member_regions", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "region_id", null: false
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_member_regions_on_member_id"
    t.index ["region_id"], name: "index_member_regions_on_region_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", limit: 32, null: false
    t.string "icon_url", limit: 2083, null: false
    t.string "discord_uid", limit: 32, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "server_joined_at"
    t.index ["discord_uid"], name: "index_members_on_discord_uid", unique: true
    t.index ["server_joined_at"], name: "index_members_on_server_joined_at"
  end

  create_table "regions", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_regions_on_code", unique: true
    t.index ["name"], name: "index_regions_on_name"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.date "date", null: false
    t.integer "status", default: 0, null: false
    t.string "memo", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "slot", default: 0, null: false
    t.index ["date"], name: "index_schedules_on_date"
    t.index ["member_id", "date", "slot"], name: "index_schedules_on_member_id_and_date_and_slot", unique: true
    t.index ["member_id"], name: "index_schedules_on_member_id"
  end

  add_foreign_key "assignments", "schedules"
  add_foreign_key "member_regions", "members"
  add_foreign_key "member_regions", "regions"
  add_foreign_key "schedules", "members"
end
