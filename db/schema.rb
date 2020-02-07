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

ActiveRecord::Schema.define(version: 2020_02_02_052500) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_id"
    t.text "content"
    t.boolean "deleted", default: false
    t.integer "user_id"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_comments_on_community_id"
    t.index ["post_id"], name: "index_comments_on_post_type_and_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "communities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "host", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host"], name: "index_communities_on_host"
  end

  create_table "community_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "community_id", null: false
    t.bigint "user_id", null: false
    t.boolean "is_moderator"
    t.boolean "is_admin"
    t.integer "reputation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_community_users_on_community_id"
    t.index ["user_id"], name: "index_community_users_on_user_id"
  end

  create_table "flags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "post_id"
    t.string "status"
    t.text "message"
    t.integer "handled_by_id"
    t.datetime "handled_at"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_flags_on_community_id"
    t.index ["post_id"], name: "index_flags_on_post_type_and_post_id"
    t.index ["user_id"], name: "index_flags_on_user_id"
  end

  create_table "notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "content"
    t.string "link"
    t.boolean "is_read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_notifications_on_community_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "post_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "post_history_type_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_id"
    t.text "before_state"
    t.text "after_state"
    t.text "comment"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_post_histories_on_community_id"
    t.index ["post_history_type_id"], name: "index_post_histories_on_post_history_type_id"
    t.index ["post_id"], name: "index_post_histories_on_post_type_and_post_id"
    t.index ["user_id"], name: "index_post_histories_on_user_id"
  end

  create_table "post_history_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_post_history_types_on_name"
  end

  create_table "post_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_post_types_on_name"
  end

  create_table "posts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.string "tags_cache"
    t.integer "score", default: 0, null: false
    t.integer "parent_id"
    t.integer "user_id"
    t.boolean "closed", default: false, null: false
    t.integer "closed_by_id"
    t.datetime "closed_at"
    t.boolean "deleted", default: false, null: false
    t.integer "deleted_by_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_type_id", null: false
    t.text "body_markdown"
    t.integer "answer_count", default: 0, null: false
    t.datetime "last_activity", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "att_source"
    t.string "att_license_name"
    t.string "att_license_link"
    t.string "doc_slug"
    t.bigint "last_activity_by_id"
    t.string "category", default: "Main"
    t.bigint "community_id", null: false
    t.index ["body_markdown"], name: "index_posts_on_body_markdown", type: :fulltext
    t.index ["category"], name: "index_posts_on_category"
    t.index ["community_id"], name: "index_posts_on_community_id"
    t.index ["last_activity_by_id"], name: "index_posts_on_last_activity_by_id"
  end

  create_table "posts_tags", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "tag_id"
    t.bigint "post_id"
    t.index ["post_id"], name: "index_posts_tags_on_post_id"
    t.index ["tag_id"], name: "index_posts_tags_on_tag_id"
  end

  create_table "privileges", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "threshold"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_privileges_on_community_id"
    t.index ["name"], name: "index_privileges_on_name"
  end

  create_table "privileges_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "privilege_id", null: false
    t.integer "user_id", null: false
    t.index ["privilege_id", "user_id"], name: "index_privileges_users_on_privilege_id_and_user_id"
    t.index ["user_id", "privilege_id"], name: "index_privileges_users_on_user_id_and_privilege_id"
  end

  create_table "site_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value_type", null: false
    t.text "description"
    t.string "category"
    t.bigint "community_id"
    t.index ["category"], name: "index_site_settings_on_category"
    t.index ["community_id"], name: "index_site_settings_on_community_id"
    t.index ["name"], name: "index_site_settings_on_name"
  end

  create_table "subscriptions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "type", null: false
    t.string "qualifier"
    t.bigint "user_id"
    t.boolean "enabled", default: true, null: false
    t.integer "frequency", null: false
    t.datetime "last_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_subscriptions_on_community_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "suspicious_votes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "from_user_id"
    t.integer "to_user_id"
    t.boolean "was_investigated", default: false
    t.integer "investigated_by"
    t.datetime "investigated_at"
    t.integer "suspicious_count"
    t.integer "total_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_tags_on_community_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_global_moderator"
    t.boolean "is_global_admin"
    t.string "username"
    t.text "profile"
    t.text "website"
    t.string "twitter"
    t.text "profile_markdown"
    t.integer "se_acct_id"
    t.boolean "transferred_content", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "votes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "vote_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "post_id"
    t.integer "recv_user_id"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_votes_on_community_id"
    t.index ["post_id"], name: "index_votes_on_post_type_and_post_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "communities"
  add_foreign_key "community_users", "communities"
  add_foreign_key "community_users", "users"
  add_foreign_key "flags", "communities"
  add_foreign_key "notifications", "communities"
  add_foreign_key "post_histories", "communities"
  add_foreign_key "posts", "communities"
  add_foreign_key "privileges", "communities"
  add_foreign_key "site_settings", "communities"
  add_foreign_key "subscriptions", "communities"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tags", "communities"
  add_foreign_key "votes", "communities"
end
