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

ActiveRecord::Schema[8.0].define(version: 2024_11_24_000267) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "application_instances", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.string "lti_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_application_instances_on_application_id"
  end

  create_table "applications", force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "atomic_tenant_lti_deployments", force: :cascade do |t|
    t.string "iss", null: false
    t.string "deployment_id", null: false
    t.bigint "application_instance_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "registered_pns_notifications_at", precision: nil
    t.index ["iss", "deployment_id"], name: "index_atomic_tenant_lti_deployments_on_iss_and_deployment_id", unique: true
  end

  create_table "atomic_tenant_pinned_client_ids", force: :cascade do |t|
    t.string "iss", null: false
    t.string "client_id", null: false
    t.bigint "application_instance_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["iss", "client_id"], name: "index_atomic_tenant_pinned_client_ids_on_iss_and_client_id", unique: true
  end

  create_table "atomic_tenant_pinned_platform_guids", force: :cascade do |t|
    t.string "iss", null: false
    t.string "platform_guid", null: false
    t.bigint "application_id", null: false
    t.bigint "application_instance_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["iss", "platform_guid", "application_id"], name: "index_pinned_platform_guids", unique: true
  end

  create_table "bad_row_security_examples", force: :cascade do |t|
    t.string "name"
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "good_row_security_examples", force: :cascade do |t|
    t.string "name"
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tenants", force: :cascade do |t|
    t.string "key", null: false
    t.bigint "id_offset"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_tenants_on_key", unique: true
  end

  add_foreign_key "application_instances", "applications"
end
