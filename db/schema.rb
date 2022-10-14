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

ActiveRecord::Schema[7.0].define(version: 2022_10_14_195907) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "sent_at", precision: nil
    t.datetime "opened_at", precision: nil
    t.datetime "clicked_at", precision: nil
    t.index ["user_type", "user_id"], name: "index_ahoy_messages_on_user_type_and_user_id"
  end

  create_table "alert_subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "token"
    t.datetime "unsubscribed_at", precision: nil
    t.datetime "confirmed_at", precision: nil
    t.bigint "netfile_agency_id", default: 1
    t.index ["netfile_agency_id"], name: "index_alert_subscribers_on_netfile_agency_id"
    t.index ["token"], name: "index_alert_subscribers_on_token"
  end

  create_table "election_candidates", force: :cascade do |t|
    t.string "election_name", null: false
    t.string "name", null: false
    t.string "fppc_id"
    t.string "office_name"
    t.boolean "incumbent"
  end

  create_table "election_committees", force: :cascade do |t|
    t.string "name"
    t.string "fppc_id"
    t.string "candidate_controlled_id"
    t.string "support_or_oppose"
    t.string "ballot_measure"
    t.string "ballot_measure_election"
  end

  create_table "election_referendums", force: :cascade do |t|
    t.string "election_name", null: false
    t.string "measure_number"
    t.string "title"
    t.string "full_title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "filed_at", precision: nil
    t.json "contents"
    t.xml "contents_xml"
    t.bigint "netfile_agency_id", default: 1
    t.index ["netfile_agency_id"], name: "index_filings_on_netfile_agency_id"
  end

  create_table "netfile_agencies", force: :cascade do |t|
    t.integer "netfile_id"
    t.string "shortcut"
    t.string "name"
    t.index ["netfile_id"], name: "index_netfile_agencies_on_netfile_id", unique: true
    t.index ["shortcut"], name: "index_netfile_agencies_on_shortcut", unique: true
  end

  create_table "notices", force: :cascade do |t|
    t.date "date"
    t.text "body"
    t.bigint "creator_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["creator_id"], name: "index_notices_on_creator_id"
  end

  add_foreign_key "notices", "admin_users", column: "creator_id"
end
