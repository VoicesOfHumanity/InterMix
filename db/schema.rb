# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20141231195725) do

  create_table "authentications", force: :cascade do |t|
    t.integer  "participant_id", limit: 4
    t.string   "provider",       limit: 255
    t.string   "uid",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",    limit: 255,             null: false
    t.string   "data_content_type", limit: 255
    t.integer  "data_file_size",    limit: 4
    t.integer  "assetable_id",      limit: 4
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 25
    t.string   "guid",              limit: 10
    t.integer  "locale",            limit: 1,   default: 0
    t.integer  "user_id",           limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width",             limit: 4
    t.integer  "height",            limit: 4
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "fk_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_assetable_type", using: :btree
  add_index "ckeditor_assets", ["user_id"], name: "fk_user", using: :btree

  create_table "dialog_admins", force: :cascade do |t|
    t.integer  "dialog_id",      limit: 4
    t.integer  "participant_id", limit: 4
    t.boolean  "active",         limit: 1, default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dialog_admins", ["dialog_id", "participant_id"], name: "index_dialog_admins_on_dialog_id_and_participant_id", using: :btree

  create_table "dialog_groups", force: :cascade do |t|
    t.integer  "dialog_id",                limit: 4
    t.integer  "group_id",                 limit: 4
    t.boolean  "active",                   limit: 1,     default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "signup_template",          limit: 65535
    t.text     "confirm_template",         limit: 65535
    t.text     "confirm_email_template",   limit: 65535
    t.text     "confirm_welcome_template", limit: 65535
    t.datetime "apply_at"
    t.integer  "apply_by",                 limit: 4,     default: 0
    t.string   "apply_status",             limit: 255,   default: ""
    t.integer  "processed_by",             limit: 4,     default: 0
  end

  add_index "dialog_groups", ["dialog_id", "group_id"], name: "index_dialog_groups_on_dialog_id_and_group_id", using: :btree
  add_index "dialog_groups", ["group_id", "dialog_id"], name: "index_dialog_groups_on_group_id_and_dialog_id", using: :btree

  create_table "dialog_metamaps", force: :cascade do |t|
    t.integer  "dialog_id",  limit: 4
    t.integer  "metamap_id", limit: 4
    t.integer  "sortorder",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dialog_metamaps", ["dialog_id", "metamap_id"], name: "index_dialog_metamaps_on_dialog_id_and_metamap_id", using: :btree
  add_index "dialog_metamaps", ["metamap_id", "dialog_id"], name: "index_dialog_metamaps_on_metamap_id_and_dialog_id", using: :btree

  create_table "dialog_participants", force: :cascade do |t|
    t.integer  "dialog_id",         limit: 4
    t.integer  "participant_id",    limit: 4
    t.boolean  "moderator",         limit: 1,   default: false
    t.boolean  "active",            limit: 1,   default: true
    t.string   "direct_email_code", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dialog_participants", ["dialog_id", "participant_id"], name: "index_dialog_participants_on_dialog_id_and_participant_id", using: :btree
  add_index "dialog_participants", ["direct_email_code"], name: "index_dialog_participants_on_direct_email_code", length: {"direct_email_code"=>20}, using: :btree
  add_index "dialog_participants", ["participant_id", "dialog_id"], name: "index_dialog_participants_on_participant_id_and_dialog_id", using: :btree

  create_table "dialogs", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.text     "description",              limit: 65535
    t.text     "shortdesc",                limit: 65535
    t.text     "instructions",             limit: 65535
    t.text     "coordinators",             limit: 65535
    t.string   "visibility",               limit: 255
    t.string   "publishing",               limit: 255
    t.integer  "max_voting_distribution",  limit: 4
    t.integer  "max_characters",           limit: 4
    t.integer  "max_words",                limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "shortname",                limit: 255
    t.integer  "created_by",               limit: 4
    t.boolean  "multigroup",               limit: 1,     default: false
    t.integer  "group_id",                 limit: 4
    t.string   "openness",                 limit: 255
    t.integer  "max_mess_length",          limit: 4
    t.text     "signup_template",          limit: 65535
    t.text     "front_template",           limit: 65535
    t.text     "confirm_template",         limit: 65535
    t.text     "confirm_email_template",   limit: 65535
    t.text     "confirm_welcome_template", limit: 65535
    t.text     "member_template",          limit: 65535
    t.text     "list_template",            limit: 65535
    t.string   "metamap_vote_own",         limit: 255
    t.string   "logo_file_name",           limit: 255
    t.string   "logo_content_type",        limit: 255
    t.integer  "logo_file_size",           limit: 4
    t.datetime "logo_updated_at"
    t.text     "default_message",          limit: 65535
    t.boolean  "required_message",         limit: 1,     default: true
    t.boolean  "required_subject",         limit: 1,     default: true
    t.boolean  "alt_logins",               limit: 1,     default: true
    t.integer  "max_messages",             limit: 4,     default: 0
    t.string   "new_message_title",        limit: 255
    t.boolean  "allow_replies",            limit: 1,     default: true
    t.boolean  "required_meta",            limit: 1,     default: true
    t.string   "value_calc",               limit: 255,   default: "total"
    t.boolean  "profiles_visible",         limit: 1,     default: true
    t.boolean  "names_visible_voting",     limit: 1,     default: true
    t.boolean  "names_visible_general",    limit: 1,     default: true
    t.boolean  "in_voting_round",          limit: 1,     default: false
    t.boolean  "posting_open",             limit: 1,     default: true
    t.boolean  "voting_open",              limit: 1,     default: true
    t.integer  "current_period",           limit: 4
    t.string   "twitter_hash_tag",         limit: 255
  end

  add_index "dialogs", ["name"], name: "index_dialogs_on_name", length: {"name"=>30}, using: :btree
  add_index "dialogs", ["shortname"], name: "index_dialogs_on_shortname", length: {"shortname"=>20}, using: :btree

  create_table "follows", force: :cascade do |t|
    t.integer  "following_id", limit: 4
    t.integer  "followed_id",  limit: 4
    t.boolean  "mutual",       limit: 1, default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "follows", ["followed_id", "following_id"], name: "index_follows_on_followed_id_and_following_id", using: :btree
  add_index "follows", ["following_id", "followed_id"], name: "index_follows_on_following_id_and_followed_id", using: :btree

  create_table "geoadmin1s", force: :cascade do |t|
    t.string  "admin1uniq",   limit: 15
    t.string  "country_code", limit: 2
    t.string  "admin1_code",  limit: 10
    t.string  "name",         limit: 255
    t.boolean "has_admin2s",  limit: 1
  end

  add_index "geoadmin1s", ["country_code", "admin1_code"], name: "admin1_code", using: :btree
  add_index "geoadmin1s", ["country_code", "name"], name: "geoadmin1s_name_index", length: {"country_code"=>nil, "name"=>20}, using: :btree

  create_table "geoadmin2s", force: :cascade do |t|
    t.string  "admin2uniq",   limit: 30
    t.string  "country_code", limit: 2
    t.string  "admin1_code",  limit: 10
    t.string  "admin2_code",  limit: 15
    t.string  "name",         limit: 255
    t.string  "name_ascii",   limit: 255
    t.integer "geoname_id",   limit: 4
    t.string  "admin1uniq",   limit: 15
  end

  add_index "geoadmin2s", ["admin1uniq"], name: "admin1uniq", using: :btree
  add_index "geoadmin2s", ["country_code", "admin1_code", "admin2_code"], name: "admin2_code", using: :btree
  add_index "geoadmin2s", ["country_code", "name"], name: "geoadmin2s_name_index", length: {"country_code"=>nil, "name"=>20}, using: :btree
  add_index "geoadmin2s", ["geoname_id"], name: "geoname_id", using: :btree

  create_table "geocountries", force: :cascade do |t|
    t.string   "iso",           limit: 2
    t.string   "iso3",          limit: 3
    t.integer  "isonum",        limit: 4
    t.string   "fips",          limit: 2
    t.string   "name",          limit: 255
    t.string   "capital",       limit: 255
    t.string   "area",          limit: 255
    t.integer  "population",    limit: 4
    t.string   "continent",     limit: 2
    t.string   "tld",           limit: 3
    t.string   "currency_code", limit: 3
    t.string   "currency_name", limit: 255
    t.integer  "phone",         limit: 4
    t.string   "zip_format",    limit: 255
    t.string   "zip_regex",     limit: 255
    t.string   "languages",     limit: 255
    t.integer  "geoname_id",    limit: 4
    t.string   "neighbors",     limit: 255
    t.string   "fips_equiv",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extrasort",     limit: 3
  end

  add_index "geocountries", ["extrasort", "name"], name: "sortname", using: :btree
  add_index "geocountries", ["iso"], name: "iso", using: :btree
  add_index "geocountries", ["name"], name: "name", using: :btree

  create_table "group_metamaps", force: :cascade do |t|
    t.integer  "group_id",   limit: 4
    t.integer  "metamap_id", limit: 4
    t.integer  "sortorder",  limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "group_metamaps", ["group_id", "metamap_id"], name: "index_group_metamaps_on_dialog_id_and_metamap_id", using: :btree
  add_index "group_metamaps", ["metamap_id", "group_id"], name: "index_group_metamaps_on_metamap_id_and_group_id", using: :btree

  create_table "group_participants", force: :cascade do |t|
    t.integer  "group_id",          limit: 4
    t.integer  "participant_id",    limit: 4
    t.boolean  "moderator",         limit: 1,   default: false
    t.boolean  "active",            limit: 1,   default: true
    t.string   "status",            limit: 255, default: "active"
    t.string   "direct_email_code", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "group_participants", ["direct_email_code"], name: "index_group_participants_on_direct_email_code", length: {"direct_email_code"=>20}, using: :btree
  add_index "group_participants", ["group_id", "participant_id"], name: "index_group_participants_on_group_id_and_participant_id", using: :btree
  add_index "group_participants", ["participant_id", "group_id"], name: "index_group_participants_on_participant_id_and_group_id", using: :btree

  create_table "group_subtag_participants", force: :cascade do |t|
    t.integer  "group_subtag_id", limit: 4
    t.integer  "group_id",        limit: 4
    t.integer  "participant_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "group_subtag_participants", ["group_subtag_id"], name: "index_group_subtag_participants_on_group_subtag_id", using: :btree
  add_index "group_subtag_participants", ["participant_id"], name: "index_group_subtag_participants_on_participant_id", using: :btree

  create_table "group_subtags", force: :cascade do |t|
    t.integer  "group_id",    limit: 4
    t.string   "tag",         limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "selfadd",     limit: 1,     default: true
    t.text     "description", limit: 65535
  end

  add_index "group_subtags", ["group_id", "tag"], name: "index_group_subtags_on_group_id_and_tag", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.string   "shortname",                limit: 255
    t.text     "description",              limit: 65535
    t.text     "shortdesc",                limit: 65535
    t.string   "instructions",             limit: 255
    t.string   "visibility",               limit: 255,   default: "public"
    t.string   "openness",                 limit: 255
    t.string   "message_visibility",       limit: 255,   default: "public"
    t.boolean  "moderation",               limit: 1,     default: false
    t.boolean  "is_network",               limit: 1,     default: false
    t.integer  "owner",                    limit: 4
    t.integer  "group_participants_count", limit: 4,     default: 0
    t.integer  "items_count",              limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "twitter_post",             limit: 1,     default: true
    t.string   "twitter_username",         limit: 255
    t.string   "twitter_oauth_token",      limit: 255
    t.string   "twitter_oauth_secret",     limit: 255
    t.string   "twitter_hash_tag",         limit: 255
    t.boolean  "has_mail_list",            limit: 1,     default: true
    t.string   "logo_file_name",           limit: 255
    t.string   "logo_content_type",        limit: 255
    t.integer  "logo_file_size",           limit: 4
    t.datetime "logo_updated_at"
    t.text     "front_template",           limit: 65535
    t.text     "member_template",          limit: 65535
    t.text     "invite_template",          limit: 65535
    t.text     "import_template",          limit: 65535
    t.text     "signup_template",          limit: 65535
    t.text     "confirm_template",         limit: 65535
    t.text     "confirm_email_template",   limit: 65535
    t.text     "confirm_welcome_template", limit: 65535
    t.boolean  "alt_logins",               limit: 1,     default: true
    t.boolean  "required_meta",            limit: 1,     default: true
    t.integer  "tweet_approval_min",       limit: 4,     default: 1
    t.string   "tweet_what",               limit: 255,   default: "roots"
    t.boolean  "tweet_subgroups",          limit: 1,     default: false
  end

  add_index "groups", ["name"], name: "index_groups_on_name", using: :btree
  add_index "groups", ["shortname"], name: "index_groups_on_shortname", length: {"shortname"=>20}, using: :btree

  create_table "help_texts", force: :cascade do |t|
    t.string   "code",        limit: 255
    t.string   "description", limit: 255
    t.text     "text",        limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "help_texts", ["code"], name: "index_help_texts_on_code", length: {"code"=>30}, using: :btree

  create_table "hub_admins", force: :cascade do |t|
    t.integer  "hub_id",         limit: 4
    t.integer  "participant_id", limit: 4
    t.boolean  "active",         limit: 1, default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hub_admins", ["hub_id", "participant_id"], name: "index_hub_admins_on_hub_id_and_participant_id", using: :btree

  create_table "hubs", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hubs", ["name"], name: "index_hubs_on_name", using: :btree

  create_table "item_deliveries", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_flags", force: :cascade do |t|
    t.integer  "item_id",        limit: 4
    t.integer  "participant_id", limit: 4
    t.text     "comment",        limit: 65535
    t.boolean  "cleared",        limit: 1,     default: false
    t.integer  "moderator_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_flags", ["item_id", "participant_id"], name: "index_item_flags_on_item_id_and_participant_id", using: :btree
  add_index "item_flags", ["moderator_id", "item_id"], name: "index_item_flags_on_moderator_id_and_item_id", using: :btree
  add_index "item_flags", ["participant_id", "item_id"], name: "index_item_flags_on_participant_id_and_item_id", using: :btree

  create_table "item_rating_summaries", force: :cascade do |t|
    t.integer  "item_id",      limit: 4
    t.string   "summary_type", limit: 15
    t.integer  "int_0_count",  limit: 4,                          default: 0
    t.integer  "int_1_count",  limit: 4,                          default: 0
    t.integer  "int_2_count",  limit: 4,                          default: 0
    t.integer  "int_3_count",  limit: 4,                          default: 0
    t.integer  "int_4_count",  limit: 4,                          default: 0
    t.integer  "int_count",    limit: 4,                          default: 0
    t.integer  "int_total",    limit: 4,                          default: 0
    t.decimal  "int_average",             precision: 6, scale: 2, default: 0.0
    t.integer  "app_n3_count", limit: 4,                          default: 0
    t.integer  "app_n2_count", limit: 4,                          default: 0
    t.integer  "app_n1_count", limit: 4,                          default: 0
    t.integer  "app_0_count",  limit: 4,                          default: 0
    t.integer  "app_p1_count", limit: 4,                          default: 0
    t.integer  "app_p2_count", limit: 4,                          default: 0
    t.integer  "app_p3_count", limit: 4,                          default: 0
    t.integer  "app_count",    limit: 4,                          default: 0
    t.integer  "app_total",    limit: 4,                          default: 0
    t.decimal  "app_average",             precision: 6, scale: 2, default: 0.0
    t.decimal  "value",                   precision: 6, scale: 2
    t.decimal  "controversy",             precision: 6, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_rating_summaries", ["app_average"], name: "index_item_rating_summaries_on_app_average", using: :btree
  add_index "item_rating_summaries", ["controversy"], name: "index_item_rating_summaries_on_controversy", using: :btree
  add_index "item_rating_summaries", ["int_average"], name: "index_item_rating_summaries_on_int_average", using: :btree
  add_index "item_rating_summaries", ["item_id"], name: "index_item_rating_summaries_on_item_id", using: :btree
  add_index "item_rating_summaries", ["value"], name: "index_item_rating_summaries_on_value", using: :btree

  create_table "items", force: :cascade do |t|
    t.string   "item_type",                limit: 255,                           default: "message"
    t.string   "media_type",               limit: 255,                           default: "text"
    t.integer  "posted_by",                limit: 4
    t.integer  "group_id",                 limit: 4
    t.integer  "dialog_id",                limit: 4
    t.integer  "dialog_round_id",          limit: 4
    t.string   "subject",                  limit: 255
    t.integer  "subject_id",               limit: 4
    t.boolean  "promoted_to_forum",        limit: 1
    t.boolean  "posted_to_forum",          limit: 1,                             default: true
    t.string   "election_area_type",       limit: 255
    t.string   "moderation_status",        limit: 255
    t.datetime "moderated_at"
    t.string   "moderated_by",             limit: 255
    t.text     "short_content",            limit: 65535
    t.text     "html_content",             limit: 65535
    t.text     "xml_content",              limit: 65535
    t.string   "link",                     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "approval",                               precision: 6, scale: 2, default: 0.0
    t.decimal  "interest",                               precision: 6, scale: 2, default: 0.0
    t.decimal  "value",                                  precision: 6, scale: 2, default: 0.0
    t.decimal  "controversy",                            precision: 6, scale: 2, default: 0.0
    t.text     "oembed_response",          limit: 65535
    t.text     "embed_code",               limit: 65535
    t.boolean  "has_picture",              limit: 1,                             default: false
    t.string   "posted_via",               limit: 255,                           default: "web"
    t.integer  "reply_to",                 limit: 4
    t.boolean  "is_first_in_thread",       limit: 1
    t.integer  "first_in_thread",          limit: 4
    t.integer  "old_message_id",           limit: 4
    t.boolean  "is_flagged",               limit: 1,                             default: false
    t.boolean  "edit_locked",              limit: 1,                             default: false
    t.integer  "period_id",                limit: 4
    t.integer  "first_in_thread_group_id", limit: 4
    t.boolean  "tweeted_user",             limit: 1,                             default: false
    t.datetime "tweeted_user_at"
    t.boolean  "tweeted_group",            limit: 1,                             default: false
    t.datetime "tweeted_group_at"
    t.boolean  "censored",                 limit: 1,                             default: false
    t.string   "geo_level",                limit: 255
  end

  add_index "items", ["created_at"], name: "index_items_on_created_at", using: :btree
  add_index "items", ["dialog_id", "created_at"], name: "index_items_on_dialog_id_and_created_at", using: :btree
  add_index "items", ["first_in_thread", "id"], name: "index_items_on_first_in_thread_and_id", using: :btree
  add_index "items", ["geo_level", "id"], name: "index_items_on_geo_level_and_id", length: {"geo_level"=>10, "id"=>nil}, using: :btree
  add_index "items", ["group_id", "created_at"], name: "index_items_on_group_id_and_created_at", using: :btree
  add_index "items", ["old_message_id"], name: "index_items_on_old_message_id", using: :btree
  add_index "items", ["period_id", "id"], name: "index_items_on_period_id_and_id", using: :btree
  add_index "items", ["posted_by", "created_at"], name: "index_items_on_posted_by_and_created_at", using: :btree

  create_table "messages", force: :cascade do |t|
    t.integer  "from_participant_id", limit: 4
    t.integer  "to_participant_id",   limit: 4
    t.integer  "to_group_id",         limit: 4
    t.integer  "template_id",         limit: 4
    t.string   "subject",             limit: 255
    t.text     "message",             limit: 65535
    t.string   "sendmethod",          limit: 255
    t.boolean  "sent",                limit: 1
    t.datetime "sent_at"
    t.integer  "response_to_id",      limit: 4
    t.boolean  "read_email",          limit: 1
    t.boolean  "read_web",            limit: 1
    t.datetime "read_at"
    t.boolean  "sender_delete",       limit: 1
    t.boolean  "recipient_delete",    limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "message_id",          limit: 255
    t.string   "mail_template",       limit: 255
    t.integer  "group_id",            limit: 4
    t.integer  "dialog_id",           limit: 4
    t.boolean  "email_sent",          limit: 1,     default: false
    t.datetime "email_sent_at"
  end

  add_index "messages", ["from_participant_id", "id"], name: "index_messages_on_from_participant_id_and_id", using: :btree
  add_index "messages", ["message_id"], name: "index_messages_on_message_id", length: {"message_id"=>30}, using: :btree
  add_index "messages", ["to_participant_id", "id"], name: "index_messages_on_to_participant_id_and_id", using: :btree

  create_table "metamap_node_participants", force: :cascade do |t|
    t.integer  "metamap_id",      limit: 4
    t.integer  "metamap_node_id", limit: 4
    t.integer  "participant_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metamap_node_participants", ["metamap_id", "metamap_node_id"], name: "metamap_node", using: :btree
  add_index "metamap_node_participants", ["metamap_node_id", "participant_id"], name: "node_particip", using: :btree
  add_index "metamap_node_participants", ["participant_id", "metamap_node_id"], name: "particip_node", using: :btree

  create_table "metamap_nodes", force: :cascade do |t|
    t.integer  "metamap_id",    limit: 4
    t.string   "name",          limit: 255
    t.string   "name_as_group", limit: 255
    t.integer  "parent_id",     limit: 4
    t.text     "description",   limit: 65535
    t.string   "sortorder",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metamap_nodes", ["metamap_id", "sortorder"], name: "index_metamap_nodes_on_metamap_id_and_sortorder", length: {"metamap_id"=>nil, "sortorder"=>10}, using: :btree
  add_index "metamap_nodes", ["parent_id"], name: "index_metamap_nodes_on_parent_id", using: :btree

  create_table "metamaps", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "created_by",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "global_default", limit: 1,   default: false
  end

  add_index "metamaps", ["created_at"], name: "index_metamaps_on_created_at", using: :btree
  add_index "metamaps", ["created_by"], name: "index_metamaps_on_created_by", using: :btree
  add_index "metamaps", ["name"], name: "index_metamaps_on_name", length: {"name"=>20}, using: :btree

  create_table "metro_areas", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "country_code",    limit: 255
    t.integer  "population",      limit: 4
    t.integer  "population_year", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metro_areas", ["country_code", "name"], name: "index_metro_areas_on_country_code_and_name", length: {"country_code"=>1, "name"=>20}, using: :btree

  create_table "participants", force: :cascade do |t|
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.string   "title",                  limit: 255
    t.text     "self_description",       limit: 65535
    t.string   "address1",               limit: 255
    t.string   "address2",               limit: 255
    t.string   "city",                   limit: 255
    t.string   "admin2uniq",             limit: 30
    t.string   "county_code",            limit: 15
    t.string   "county_name",            limit: 255
    t.string   "admin1uniq",             limit: 15
    t.string   "state_code",             limit: 10
    t.string   "state_name",             limit: 255
    t.string   "country_code",           limit: 2
    t.string   "country_name",           limit: 255
    t.string   "zip",                    limit: 255
    t.string   "phone",                  limit: 255
    t.decimal  "latitude",                             precision: 11, scale: 6
    t.decimal  "longitude",                            precision: 11, scale: 6
    t.string   "timezone",               limit: 255
    t.decimal  "timezone_offset",                      precision: 5,  scale: 1
    t.string   "metropolitan_area",      limit: 255
    t.integer  "metro_area_id",          limit: 4
    t.string   "bioregion",              limit: 255
    t.integer  "bioregion_id",           limit: 4
    t.string   "faith_tradition",        limit: 255
    t.integer  "faith_tradition_id",     limit: 4
    t.string   "political",              limit: 255
    t.integer  "political_id",           limit: 4
    t.string   "status",                 limit: 255
    t.string   "email",                  limit: 255,                            default: "",               null: false
    t.string   "old_email",              limit: 255
    t.string   "encrypted_password",     limit: 128,                            default: "",               null: false
    t.string   "password_salt",          limit: 255,                            default: "",               null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.string   "remember_token",         limit: 255
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,                              default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "sysadmin",               limit: 1,                              default: false
    t.integer  "items_count",            limit: 4,                              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fb_uid",                 limit: 255
    t.string   "fb_link",                limit: 255
    t.string   "visibility",             limit: 255,                            default: "visible_to_all"
    t.string   "wall_visibility",        limit: 255,                            default: "all"
    t.boolean  "item_to_forum",          limit: 1,                              default: true
    t.boolean  "twitter_post",           limit: 1,                              default: true
    t.string   "twitter_username",       limit: 255
    t.string   "twitter_oauth_token",    limit: 255
    t.string   "twitter_oauth_secret",   limit: 255
    t.string   "forum_email",            limit: 255,                            default: "never"
    t.string   "group_email",            limit: 255,                            default: "instant"
    t.string   "subgroup_email",         limit: 255,                            default: "instant"
    t.string   "private_email",          limit: 255,                            default: "instant"
    t.string   "system_email",           limit: 255,                            default: "instant"
    t.boolean  "no_email",               limit: 1,                              default: false
    t.string   "direct_email_code",      limit: 255
    t.boolean  "has_participated",       limit: 1,                              default: false
    t.integer  "old_user_id",            limit: 4
    t.text     "forum_settings",         limit: 65535
    t.string   "last_url",               limit: 255
    t.string   "handle",                 limit: 255
    t.string   "authentication_token",   limit: 255
    t.boolean  "new_signup",             limit: 1,                              default: true
    t.boolean  "dialog_pop_shown",       limit: 1,                              default: false
    t.boolean  "required_entered",       limit: 1,                              default: false
    t.integer  "last_group_id",          limit: 4
    t.integer  "last_dialog_id",         limit: 4
    t.string   "provider",               limit: 255
    t.string   "uid",                    limit: 255
    t.string   "disc_interface",         limit: 255,                            default: "simple"
    t.string   "picture_file_name",      limit: 255
    t.string   "picture_content_type",   limit: 255
    t.integer  "picture_file_size",      limit: 4
    t.datetime "picture_updated_at"
  end

  add_index "participants", ["confirmation_token"], name: "index_participants_on_confirmation_token", unique: true, using: :btree
  add_index "participants", ["country_code", "state_code", "city"], name: "index_participants_on_country_code_and_state_code_and_city", length: {"country_code"=>nil, "state_code"=>nil, "city"=>20}, using: :btree
  add_index "participants", ["direct_email_code"], name: "index_participants_on_direct_email_code", length: {"direct_email_code"=>20}, using: :btree
  add_index "participants", ["email"], name: "index_participants_on_email", unique: true, using: :btree
  add_index "participants", ["last_name", "first_name"], name: "index_participants_on_last_name_and_first_name", length: {"last_name"=>20, "first_name"=>20}, using: :btree
  add_index "participants", ["old_user_id"], name: "index_participants_on_old_user_id", using: :btree
  add_index "participants", ["reset_password_token"], name: "index_participants_on_reset_password_token", unique: true, using: :btree

  create_table "periods", force: :cascade do |t|
    t.date     "startdate"
    t.date     "enddate"
    t.date     "endposting"
    t.date     "endrating"
    t.string   "name",                  limit: 255
    t.string   "shortname",             limit: 255
    t.string   "group_dialog",          limit: 255,      default: "dialog"
    t.integer  "group_id",              limit: 4
    t.integer  "dialog_id",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description",           limit: 65535
    t.text     "shortdesc",             limit: 65535
    t.text     "instructions",          limit: 65535
    t.text     "metamaps",              limit: 65535
    t.boolean  "metamaps_frozen",       limit: 1,        default: false
    t.integer  "max_characters",        limit: 4
    t.integer  "max_words",             limit: 4
    t.string   "metamap_vote_own",      limit: 255
    t.text     "default_message",       limit: 65535
    t.boolean  "required_message",      limit: 1,        default: true
    t.boolean  "required_subject",      limit: 1,        default: true
    t.integer  "max_messages",          limit: 4,        default: 0
    t.string   "new_message_title",     limit: 255
    t.boolean  "allow_replies",         limit: 1,        default: true
    t.boolean  "required_meta",         limit: 1,        default: true
    t.string   "value_calc",            limit: 255,      default: "total"
    t.boolean  "profiles_visible",      limit: 1,        default: true
    t.boolean  "names_visible_voting",  limit: 1,        default: true
    t.boolean  "names_visible_general", limit: 1,        default: true
    t.boolean  "in_voting_round",       limit: 1,        default: false
    t.boolean  "posting_open",          limit: 1,        default: true
    t.boolean  "voting_open",           limit: 1,        default: true
    t.integer  "sort_metamap_id",       limit: 4
    t.string   "sort_order",            limit: 255,      default: "date"
    t.string   "crosstalk",             limit: 255,      default: "none"
    t.integer  "period_number",         limit: 4,        default: 0
    t.text     "result",                limit: 16777215
  end

  add_index "periods", ["dialog_id", "startdate"], name: "index_periods_on_dialog_id_and_startdate", using: :btree
  add_index "periods", ["group_id", "startdate"], name: "index_periods_on_group_id_and_startdate", using: :btree

  create_table "photos", force: :cascade do |t|
    t.integer  "participant_id", limit: 4
    t.text     "caption",        limit: 65535
    t.string   "filename",       limit: 255
    t.integer  "filesize",       limit: 4
    t.integer  "width",          limit: 4
    t.integer  "height",         limit: 4
    t.string   "filetype",       limit: 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "photos", ["participant_id"], name: "index_photos_on_participant_id", using: :btree

  create_table "ratings", force: :cascade do |t|
    t.integer  "item_id",         limit: 4
    t.integer  "participant_id",  limit: 4
    t.string   "rating_type",     limit: 15
    t.integer  "group_id",        limit: 4
    t.integer  "dialog_id",       limit: 4
    t.integer  "dialog_round_id", limit: 4
    t.integer  "approval",        limit: 4
    t.integer  "interest",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "period_id",       limit: 4
  end

  add_index "ratings", ["group_id", "id"], name: "index_ratings_on_group_id_and_id", using: :btree
  add_index "ratings", ["item_id", "id"], name: "index_ratings_on_item_id_and_id", using: :btree
  add_index "ratings", ["participant_id", "id"], name: "index_ratings_on_participant_id_and_id", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, length: {"tag_id"=>nil, "taggable_id"=>nil, "taggable_type"=>15, "context"=>15, "tagger_id"=>nil, "tagger_type"=>15}, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", length: {"taggable_id"=>nil, "taggable_type"=>15, "context"=>15}, using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "templates", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "section",    limit: 20
    t.string   "mail_web",   limit: 4
    t.string   "title",      limit: 255
    t.text     "html_body",  limit: 65535
    t.text     "footer",     limit: 65535
    t.integer  "dialog_id",  limit: 4
    t.integer  "group_id",   limit: 4
    t.integer  "round_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "templates", ["dialog_id"], name: "index_templates_on_dialog_id", using: :btree
  add_index "templates", ["group_id"], name: "index_templates_on_group_id", using: :btree
  add_index "templates", ["round_id"], name: "index_templates_on_round_id", using: :btree
  add_index "templates", ["section"], name: "index_templates_on_section", using: :btree

end
