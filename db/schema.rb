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

ActiveRecord::Schema[7.0].define(version: 2023_08_17_213150) do
  create_table "abilities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "community_id"
    t.string "name"
    t.text "description"
    t.string "internal_id"
    t.string "icon"
    t.decimal "post_score_threshold", precision: 10, scale: 8
    t.decimal "edit_score_threshold", precision: 10, scale: 8
    t.decimal "flag_score_threshold", precision: 10, scale: 8
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "summary"
    t.index ["community_id"], name: "index_abilities_on_community_id"
  end

  create_table "ability_queues", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "community_user_id"
    t.text "comment"
    t.boolean "completed"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_user_id"], name: "index_ability_queues_on_community_user_id"
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "log_type"
    t.string "event_type"
    t.string "related_type"
    t.bigint "related_id"
    t.bigint "user_id"
    t.text "comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "community_id"
    t.index ["community_id"], name: "index_audit_logs_on_community_id"
    t.index ["event_type"], name: "index_audit_logs_on_event_type"
    t.index ["log_type"], name: "index_audit_logs_on_log_type"
    t.index ["related_type", "related_id"], name: "index_audit_logs_on_related_type_and_related_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "blocked_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type"
    t.text "value"
    t.datetime "expires", precision: nil
    t.boolean "automatic"
    t.string "reason"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "short_wiki", size: :medium
    t.bigint "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "display_post_types", size: :medium
    t.boolean "is_homepage"
    t.bigint "tag_set_id"
    t.integer "min_trust_level"
    t.string "button_text"
    t.string "color_code"
    t.text "asking_guidance_override", size: :medium
    t.text "answering_guidance_override", size: :medium
    t.integer "min_view_trust_level"
    t.bigint "license_id"
    t.integer "sequence"
    t.boolean "use_for_hot_posts", default: true
    t.boolean "use_for_advertisement", default: true
    t.integer "min_title_length", default: 15, null: false
    t.integer "min_body_length", default: 30, null: false
    t.bigint "default_filter_id"
    t.index ["community_id"], name: "index_categories_on_community_id"
    t.index ["default_filter_id"], name: "index_categories_on_default_filter_id"
    t.index ["license_id"], name: "index_categories_on_license_id"
    t.index ["sequence"], name: "index_categories_on_sequence"
    t.index ["tag_set_id"], name: "index_categories_on_tag_set_id"
  end

  create_table "categories_moderator_tags", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "tag_id"
  end

  create_table "categories_post_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "post_type_id", null: false
    t.integer "upvote_rep", default: 0, null: false
    t.integer "downvote_rep", default: 0, null: false
    t.index ["category_id", "post_type_id"], name: "index_categories_post_types_on_category_id_and_post_type_id", unique: true
  end

  create_table "categories_required_tags", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "tag_id"
  end

  create_table "categories_topic_tags", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "tag_id"
  end

  create_table "category_filter_defaults", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "filter_id", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_category_filter_defaults_on_category_id"
    t.index ["filter_id"], name: "index_category_filter_defaults_on_filter_id"
    t.index ["user_id"], name: "index_category_filter_defaults_on_user_id"
  end

  create_table "close_reasons", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description", size: :medium
    t.boolean "active"
    t.boolean "requires_other_post"
    t.bigint "community_id"
    t.index ["community_id"], name: "index_close_reasons_on_community_id"
  end

  create_table "comment_threads", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.integer "reply_count", default: 0, null: false
    t.bigint "post_id"
    t.boolean "locked", default: false, null: false
    t.bigint "locked_by_id"
    t.timestamp "locked_until"
    t.boolean "archived", default: false, null: false
    t.bigint "archived_by_id"
    t.boolean "ever_archived_before"
    t.boolean "deleted", default: false, null: false
    t.bigint "deleted_by_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "community_id", null: false
    t.boolean "is_private", default: false
    t.index ["archived_by_id"], name: "index_comment_threads_on_archived_by_id"
    t.index ["community_id"], name: "index_comment_threads_on_community_id"
    t.index ["deleted_by_id"], name: "index_comment_threads_on_deleted_by_id"
    t.index ["locked_by_id"], name: "index_comment_threads_on_locked_by_id"
    t.index ["post_id"], name: "index_comment_threads_on_post_id"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "post_id"
    t.text "content"
    t.boolean "deleted", default: false
    t.integer "user_id"
    t.bigint "community_id", null: false
    t.bigint "comment_thread_id"
    t.boolean "has_reference", default: false, null: false
    t.text "reference_text"
    t.bigint "references_comment_id"
    t.index ["comment_thread_id"], name: "index_comments_on_comment_thread_id"
    t.index ["community_id"], name: "index_comments_on_community_id"
    t.index ["post_id"], name: "index_comments_on_post_type_and_post_id"
    t.index ["references_comment_id"], name: "index_comments_on_references_comment_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "communities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "host", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_fake", default: false
    t.boolean "hidden", default: false
    t.index ["host"], name: "index_communities_on_host"
  end

  create_table "community_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "community_id", null: false
    t.bigint "user_id", null: false
    t.boolean "is_moderator"
    t.boolean "is_admin"
    t.integer "reputation"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_suspended"
    t.datetime "suspension_end", precision: nil
    t.string "suspension_public_comment"
    t.integer "trust_level"
    t.boolean "deleted", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.bigint "deleted_by_id"
    t.index ["community_id"], name: "index_community_users_on_community_id"
    t.index ["deleted_by_id"], name: "index_community_users_on_deleted_by_id"
    t.index ["user_id"], name: "index_community_users_on_user_id"
  end

  create_table "error_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "community_id"
    t.bigint "user_id"
    t.string "klass"
    t.text "message", size: :medium
    t.text "backtrace", size: :medium
    t.text "request_uri", size: :medium, null: false
    t.string "host", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "uuid"
    t.string "user_agent"
    t.index ["community_id"], name: "index_error_logs_on_community_id"
    t.index ["user_id"], name: "index_error_logs_on_user_id"
  end

  create_table "filters", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.float "min_score"
    t.float "max_score"
    t.integer "min_answers"
    t.integer "max_answers"
    t.string "status"
    t.string "include_tags"
    t.string "exclude_tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "flags", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "reason"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.integer "post_id"
    t.string "status"
    t.text "message"
    t.integer "handled_by_id"
    t.datetime "handled_at", precision: nil
    t.bigint "community_id", null: false
    t.bigint "post_flag_type_id"
    t.string "post_type"
    t.boolean "escalated", default: false, null: false
    t.datetime "escalated_at", precision: nil
    t.text "escalation_comment"
    t.bigint "escalated_by_id"
    t.index ["community_id"], name: "index_flags_on_community_id"
    t.index ["escalated_by_id"], name: "index_flags_on_escalated_by_id"
    t.index ["post_flag_type_id"], name: "index_flags_on_post_flag_type_id"
    t.index ["post_type", "post_id"], name: "index_flags_on_post_type_and_post_id"
    t.index ["status"], name: "index_flags_on_status"
    t.index ["user_id"], name: "index_flags_on_user_id"
  end

  create_table "licenses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.boolean "default"
    t.bigint "community_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "enabled", default: true
    t.text "description"
    t.index ["community_id"], name: "index_licenses_on_community_id"
    t.index ["name"], name: "index_licenses_on_name"
  end

  create_table "micro_auth_apps", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "app_id"
    t.string "public_key"
    t.string "secret_key"
    t.text "description"
    t.string "auth_domain"
    t.bigint "user_id"
    t.boolean "active", default: true, null: false
    t.bigint "deactivated_by_id"
    t.datetime "deactivated_at", precision: nil
    t.string "deactivate_comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["app_id"], name: "index_micro_auth_apps_on_app_id"
    t.index ["deactivated_by_id"], name: "index_micro_auth_apps_on_deactivated_by_id"
    t.index ["public_key"], name: "index_micro_auth_apps_on_public_key"
    t.index ["secret_key"], name: "index_micro_auth_apps_on_secret_key"
    t.index ["user_id"], name: "index_micro_auth_apps_on_user_id"
  end

  create_table "micro_auth_tokens", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "app_id"
    t.bigint "user_id"
    t.string "token"
    t.datetime "expires_at", precision: nil
    t.text "scope"
    t.string "code"
    t.datetime "code_expires_at", precision: nil
    t.text "redirect_uri"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["app_id"], name: "index_micro_auth_tokens_on_app_id"
    t.index ["user_id"], name: "index_micro_auth_tokens_on_user_id"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.string "link"
    t.boolean "is_read", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_notifications_on_community_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pinned_links", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "community_id"
    t.string "label"
    t.string "link"
    t.bigint "post_id"
    t.boolean "active"
    t.datetime "shown_after", precision: nil
    t.datetime "shown_before", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_pinned_links_on_community_id"
    t.index ["post_id"], name: "index_pinned_links_on_post_id"
  end

  create_table "post_flag_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "community_id"
    t.string "name"
    t.text "description"
    t.boolean "confidential"
    t.boolean "active"
    t.bigint "post_type_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "requires_details", default: false, null: false
    t.index ["community_id"], name: "index_post_flag_types_on_community_id"
    t.index ["post_type_id"], name: "index_post_flag_types_on_post_type_id"
  end

  create_table "post_histories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "post_history_type_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "post_id"
    t.text "before_state"
    t.text "after_state"
    t.text "comment"
    t.bigint "community_id"
    t.string "before_title"
    t.string "after_title"
    t.boolean "hidden", default: false, null: false
    t.index ["community_id"], name: "index_post_histories_on_community_id"
    t.index ["post_history_type_id"], name: "index_post_histories_on_post_history_type_id"
    t.index ["post_id"], name: "index_post_histories_on_post_type_and_post_id"
    t.index ["user_id"], name: "index_post_histories_on_user_id"
  end

  create_table "post_history_tags", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "post_history_id"
    t.bigint "tag_id"
    t.string "relationship"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["post_history_id"], name: "index_post_history_tags_on_post_history_id"
    t.index ["tag_id"], name: "index_post_history_tags_on_tag_id"
  end

  create_table "post_history_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_post_history_types_on_name"
  end

  create_table "post_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "has_answers", default: false, null: false
    t.boolean "has_votes", default: false, null: false
    t.boolean "has_tags", default: false, null: false
    t.boolean "has_parent", default: false, null: false
    t.boolean "has_category", default: false, null: false
    t.boolean "has_license", default: false, null: false
    t.boolean "is_public_editable", default: false, null: false
    t.boolean "is_closeable", default: false, null: false
    t.boolean "is_top_level", default: false, null: false
    t.boolean "is_freely_editable", default: false, null: false
    t.string "icon_name"
    t.bigint "answer_type_id"
    t.boolean "has_reactions"
    t.boolean "has_only_specific_reactions"
    t.index ["answer_type_id"], name: "index_post_types_on_answer_type_id"
    t.index ["name"], name: "index_post_types_on_name"
  end

  create_table "posts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.string "tags_cache"
    t.decimal "score", precision: 10, scale: 8, default: "0.0", null: false
    t.integer "parent_id"
    t.integer "user_id"
    t.boolean "closed", default: false, null: false
    t.integer "closed_by_id"
    t.datetime "closed_at", precision: nil
    t.boolean "deleted", default: false, null: false
    t.integer "deleted_by_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "post_type_id", null: false
    t.text "body_markdown"
    t.integer "answer_count", default: 0, null: false
    t.datetime "last_activity", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "att_source"
    t.string "att_license_name"
    t.string "att_license_link"
    t.string "doc_slug"
    t.bigint "last_activity_by_id"
    t.bigint "community_id"
    t.bigint "close_reason_id"
    t.bigint "duplicate_post_id"
    t.bigint "category_id"
    t.bigint "license_id"
    t.string "help_category"
    t.integer "help_ordering"
    t.integer "upvote_count", default: 0, null: false
    t.integer "downvote_count", default: 0, null: false
    t.boolean "comments_disabled"
    t.datetime "last_edited_at", precision: nil
    t.bigint "last_edited_by_id"
    t.boolean "locked", default: false, null: false
    t.bigint "locked_by_id"
    t.datetime "locked_at", precision: nil
    t.datetime "locked_until", precision: nil
    t.index ["att_source"], name: "index_posts_on_att_source"
    t.index ["body_markdown"], name: "index_posts_on_body_markdown", type: :fulltext
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["close_reason_id"], name: "index_posts_on_close_reason_id"
    t.index ["community_id"], name: "index_posts_on_community_id"
    t.index ["deleted"], name: "index_posts_on_deleted"
    t.index ["downvote_count"], name: "index_posts_on_downvote_count"
    t.index ["duplicate_post_id"], name: "index_posts_on_duplicate_post_id"
    t.index ["last_activity"], name: "index_posts_on_last_activity"
    t.index ["last_activity_by_id"], name: "index_posts_on_last_activity_by_id"
    t.index ["last_edited_by_id"], name: "index_posts_on_last_edited_by_id"
    t.index ["license_id"], name: "index_posts_on_license_id"
    t.index ["locked_by_id"], name: "index_posts_on_locked_by_id"
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["post_type_id"], name: "index_posts_on_post_type_id"
    t.index ["score"], name: "index_posts_on_score"
    t.index ["tags_cache"], name: "index_posts_on_tags_cache"
    t.index ["upvote_count"], name: "index_posts_on_upvote_count"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "posts_tags", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "tag_id"
    t.bigint "post_id"
    t.index ["post_id", "tag_id"], name: "index_posts_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_posts_tags_on_post_id"
    t.index ["tag_id"], name: "index_posts_tags_on_tag_id"
  end

  create_table "privileges", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.integer "threshold"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_privileges_on_community_id"
    t.index ["name"], name: "index_privileges_on_name"
  end

  create_table "privileges_users", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "privilege_id", null: false
    t.integer "user_id", null: false
    t.index ["privilege_id", "user_id"], name: "index_privileges_users_on_privilege_id_and_user_id"
    t.index ["user_id", "privilege_id"], name: "index_privileges_users_on_user_id_and_privilege_id"
  end

  create_table "reaction_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "on_post_label"
    t.string "icon"
    t.string "color"
    t.boolean "requires_comment"
    t.bigint "community_id"
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active"
    t.bigint "post_type_id"
    t.index ["community_id"], name: "index_reaction_types_on_community_id"
    t.index ["post_type_id"], name: "index_reaction_types_on_post_type_id"
  end

  create_table "reactions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "reaction_type_id"
    t.bigint "post_id"
    t.bigint "comment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["comment_id"], name: "index_reactions_on_comment_id"
    t.index ["post_id"], name: "index_reactions_on_post_id"
    t.index ["reaction_type_id"], name: "index_reactions_on_reaction_type_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "site_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "value_type", null: false
    t.text "description"
    t.string "category"
    t.bigint "community_id"
    t.index ["category"], name: "index_site_settings_on_category"
    t.index ["community_id"], name: "index_site_settings_on_community_id"
    t.index ["name"], name: "index_site_settings_on_name"
  end

  create_table "sso_profiles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "saml_identifier", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sso_profiles_on_user_id"
  end

  create_table "subscriptions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "type", null: false
    t.string "qualifier"
    t.bigint "user_id"
    t.boolean "enabled", default: true, null: false
    t.integer "frequency", null: false
    t.datetime "last_sent_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_subscriptions_on_community_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "suggested_edits", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "post_id"
    t.bigint "user_id"
    t.bigint "community_id"
    t.text "body"
    t.string "title"
    t.string "tags_cache"
    t.text "body_markdown"
    t.string "comment"
    t.boolean "active"
    t.boolean "accepted"
    t.datetime "decided_at", precision: nil
    t.bigint "decided_by_id"
    t.string "rejected_comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "before_title"
    t.text "before_body"
    t.text "before_body_markdown"
    t.string "before_tags_cache"
    t.index ["community_id"], name: "index_suggested_edits_on_community_id"
    t.index ["decided_by_id"], name: "index_suggested_edits_on_decided_by_id"
    t.index ["post_id"], name: "index_suggested_edits_on_post_id"
    t.index ["user_id"], name: "index_suggested_edits_on_user_id"
  end

  create_table "suggested_edits_before_tags", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "suggested_edit_id", null: false
    t.bigint "tag_id", null: false
  end

  create_table "suggested_edits_tags", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "suggested_edit_id", null: false
    t.bigint "tag_id", null: false
  end

  create_table "tag_sets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "community_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_tag_sets_on_community_id"
  end

  create_table "tag_synonyms", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tag_synonyms_on_tag_id"
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "community_id", null: false
    t.bigint "tag_set_id", null: false
    t.text "wiki_markdown"
    t.text "wiki"
    t.text "excerpt"
    t.bigint "parent_id"
    t.index ["community_id"], name: "index_tags_on_community_id"
    t.index ["parent_id"], name: "index_tags_on_parent_id"
    t.index ["tag_set_id"], name: "index_tags_on_tag_set_id"
  end

  create_table "thread_followers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "comment_thread_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "post_id"
    t.index ["comment_thread_id"], name: "index_thread_followers_on_comment_thread_id"
    t.index ["post_id"], name: "index_thread_followers_on_post_id"
    t.index ["user_id"], name: "index_thread_followers_on_user_id"
  end

  create_table "user_abilities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "community_user_id"
    t.bigint "ability_id"
    t.boolean "is_suspended", default: false
    t.datetime "suspension_end", precision: nil
    t.text "suspension_message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ability_id"], name: "index_user_abilities_on_ability_id"
    t.index ["community_user_id"], name: "index_user_abilities_on_community_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_global_moderator"
    t.boolean "is_global_admin"
    t.string "username"
    t.text "profile"
    t.text "website"
    t.string "twitter"
    t.text "profile_markdown"
    t.integer "se_acct_id"
    t.boolean "transferred_content", default: false
    t.string "login_token"
    t.datetime "login_token_expires_at", precision: nil
    t.string "two_factor_token"
    t.boolean "enabled_2fa", default: false
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "two_factor_method"
    t.boolean "staff", default: false, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.integer "trust_level"
    t.boolean "developer"
    t.string "cid"
    t.string "discord"
    t.boolean "deleted", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.bigint "deleted_by_id"
    t.boolean "is_globally_suspended", default: false
    t.datetime "global_suspension_end", precision: nil
    t.string "backup_2fa_code"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_by_id"], name: "index_users_on_deleted_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "votes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "vote_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.integer "post_id"
    t.integer "recv_user_id"
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_votes_on_community_id"
    t.index ["post_id"], name: "index_votes_on_post_type_and_post_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  create_table "warning_templates", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "community_id"
    t.string "name"
    t.text "body"
    t.boolean "active"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_warning_templates_on_community_id"
  end

  create_table "warnings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "community_user_id"
    t.text "body"
    t.boolean "is_suspension"
    t.datetime "suspension_end", precision: nil
    t.boolean "active"
    t.bigint "author_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "read", default: false
    t.boolean "is_global", default: false
    t.bigint "user_id"
    t.index ["author_id"], name: "index_mod_messages_on_author_id"
    t.index ["community_user_id"], name: "index_mod_messages_on_community_user_id"
    t.index ["user_id"], name: "index_warnings_on_user_id"
  end

  add_foreign_key "abilities", "communities"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "communities"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "categories", "filters", column: "default_filter_id"
  add_foreign_key "categories", "licenses"
  add_foreign_key "categories", "tag_sets"
  add_foreign_key "category_filter_defaults", "categories"
  add_foreign_key "category_filter_defaults", "filters"
  add_foreign_key "category_filter_defaults", "users"
  add_foreign_key "comment_threads", "users", column: "archived_by_id"
  add_foreign_key "comment_threads", "users", column: "deleted_by_id"
  add_foreign_key "comment_threads", "users", column: "locked_by_id"
  add_foreign_key "comments", "comments", column: "references_comment_id"
  add_foreign_key "comments", "communities"
  add_foreign_key "community_users", "communities"
  add_foreign_key "community_users", "users"
  add_foreign_key "community_users", "users", column: "deleted_by_id"
  add_foreign_key "error_logs", "communities"
  add_foreign_key "error_logs", "users"
  add_foreign_key "filters", "users"
  add_foreign_key "flags", "communities"
  add_foreign_key "flags", "users", column: "escalated_by_id"
  add_foreign_key "micro_auth_apps", "users"
  add_foreign_key "micro_auth_apps", "users", column: "deactivated_by_id"
  add_foreign_key "micro_auth_tokens", "micro_auth_apps", column: "app_id"
  add_foreign_key "micro_auth_tokens", "users"
  add_foreign_key "notifications", "communities"
  add_foreign_key "pinned_links", "communities"
  add_foreign_key "pinned_links", "posts"
  add_foreign_key "post_histories", "communities"
  add_foreign_key "post_history_tags", "post_histories"
  add_foreign_key "post_history_tags", "tags"
  add_foreign_key "post_types", "post_types", column: "answer_type_id"
  add_foreign_key "posts", "close_reasons"
  add_foreign_key "posts", "communities"
  add_foreign_key "posts", "licenses"
  add_foreign_key "posts", "posts", column: "duplicate_post_id"
  add_foreign_key "posts", "users", column: "locked_by_id"
  add_foreign_key "privileges", "communities"
  add_foreign_key "site_settings", "communities"
  add_foreign_key "sso_profiles", "users"
  add_foreign_key "subscriptions", "communities"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "suggested_edits", "communities"
  add_foreign_key "suggested_edits", "posts"
  add_foreign_key "suggested_edits", "users"
  add_foreign_key "suggested_edits", "users", column: "decided_by_id"
  add_foreign_key "tag_synonyms", "tags"
  add_foreign_key "tags", "communities"
  add_foreign_key "tags", "tags", column: "parent_id"
  add_foreign_key "thread_followers", "posts"
  add_foreign_key "user_abilities", "abilities"
  add_foreign_key "user_abilities", "community_users"
  add_foreign_key "users", "users", column: "deleted_by_id"
  add_foreign_key "votes", "communities"
  add_foreign_key "warning_templates", "communities"
  add_foreign_key "warnings", "community_users"
  add_foreign_key "warnings", "users", column: "author_id"
end
