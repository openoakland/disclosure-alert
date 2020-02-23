# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_02_23_005208) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "ahoy_messages", force: :cascade do |t|
    t.string "user_type"
    t.bigint "user_id"
    t.text "to"
    t.string "mailer"
    t.text "subject"
    t.string "token"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.index ["user_type", "user_id"], name: "index_ahoy_messages_on_user_type_and_user_id"
  end

  create_table "alert_subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token"
    t.datetime "unsubscribed_at"
    t.index ["token"], name: "index_alert_subscribers_on_token"
  end

  create_table "election_candidates", force: :cascade do |t|
    t.string "election_name", null: false
    t.string "name", null: false
    t.string "fppc_id"
    t.string "office_name"
    t.boolean "incumbent"
  end

  create_table "election_referendums", force: :cascade do |t|
    t.string "election_name", null: false
    t.string "measure_number"
    t.string "title"
    t.string "full_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "elections", force: :cascade do |t|
    t.string "slug", null: false
    t.string "location", null: false
    t.date "date", null: false
    t.string "title", null: false
    t.date "deadline_semi_annual_pre_pre"
    t.date "deadline_semi_annual_pre"
    t.date "deadline_1st_pre_election"
    t.date "deadline_2nd_pre_election"
    t.date "deadline_semi_annual_post"
  end

  create_table "filings", force: :cascade do |t|
    t.string "filer_id"
    t.string "filer_name"
    t.string "title"
    t.string "amendment_sequence_number"
    t.string "amended_filing_id"
    t.string "form"
    t.datetime "filed_at"
    t.json "contents"
    t.xml "contents_xml"
  end

end
