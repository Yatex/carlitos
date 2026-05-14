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

ActiveRecord::Schema[7.1].define(version: 2026_05_13_103000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assistant_messages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "direction", null: false
    t.string "channel", null: false
    t.text "body", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata"], name: "index_assistant_messages_on_metadata", using: :gin
    t.index ["user_id", "created_at"], name: "index_assistant_messages_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_assistant_messages_on_user_id"
  end

  create_table "assistant_runs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "input", null: false
    t.text "output"
    t.string "status", default: "pending", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata"], name: "index_assistant_runs_on_metadata", using: :gin
    t.index ["user_id", "created_at"], name: "index_assistant_runs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_assistant_runs_on_user_id"
  end

  create_table "daily_briefings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "enabled", default: false, null: false
    t.time "delivery_time", default: "2000-01-01 08:00:00", null: false
    t.string "timezone", default: "America/Montevideo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_daily_briefings_on_user_id", unique: true
  end

  create_table "early_access_signups", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_early_access_signups_on_email", unique: true
  end

  create_table "integration_connections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "status", default: "disconnected", null: false
    t.string "display_name"
    t.string "external_id"
    t.datetime "connected_at"
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata"], name: "index_integration_connections_on_metadata", using: :gin
    t.index ["user_id", "provider"], name: "index_integration_connections_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_integration_connections_on_user_id"
  end

  create_table "memory_list_items", force: :cascade do |t|
    t.bigint "memory_list_id", null: false
    t.string "content", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memory_list_id", "completed_at"], name: "index_memory_list_items_on_memory_list_id_and_completed_at"
    t.index ["memory_list_id"], name: "index_memory_list_items_on_memory_list_id"
  end

  create_table "memory_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "title"], name: "index_memory_lists_on_user_id_and_title"
    t.index ["user_id"], name: "index_memory_lists_on_user_id"
  end

  create_table "memory_notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.string "source", default: "web", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_memory_notes_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_memory_notes_on_user_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "remind_at"
    t.string "recurrence_rule"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "remind_at"], name: "index_reminders_on_user_id_and_remind_at"
    t.index ["user_id", "status"], name: "index_reminders_on_user_id_and_status"
    t.index ["user_id"], name: "index_reminders_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.string "timezone", default: "America/Montevideo", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status", default: "free", null: false
    t.string "current_plan", default: "free", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.integer "role", default: 0, null: false
    t.datetime "plan_expires_at"
    t.datetime "plan_granted_at"
    t.bigint "plan_granted_by_id"
    t.string "google_uid"
    t.datetime "google_connected_at"
    t.boolean "google_email_verified", default: false, null: false
    t.datetime "free_trial_started_at"
    t.datetime "free_trial_ends_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["free_trial_ends_at"], name: "index_users_on_free_trial_ends_at"
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["plan_expires_at"], name: "index_users_on_plan_expires_at"
    t.index ["plan_granted_by_id"], name: "index_users_on_plan_granted_by_id"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "assistant_messages", "users"
  add_foreign_key "assistant_runs", "users"
  add_foreign_key "daily_briefings", "users"
  add_foreign_key "integration_connections", "users"
  add_foreign_key "memory_list_items", "memory_lists"
  add_foreign_key "memory_lists", "users"
  add_foreign_key "memory_notes", "users"
  add_foreign_key "reminders", "users"
  add_foreign_key "users", "users", column: "plan_granted_by_id"
end
