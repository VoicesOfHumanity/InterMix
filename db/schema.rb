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

ActiveRecord::Schema.define(version: 2022_06_21_204744) do

  create_table "api_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "path"
    t.text "request_body"
    t.text "request_headers"
    t.string "request_method"
    t.string "request_content_type"
    t.string "user_agent"
    t.string "remote_ip"
    t.string "our_function"
    t.boolean "processed", default: false
    t.boolean "problem", default: false
    t.boolean "redo", default: false
    t.text "response_body"
    t.string "account_uniq", limit: 12, default: ""
    t.integer "participant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["our_function"], name: "index_api_requests_on_our_function"
    t.index ["participant_id"], name: "index_api_requests_on_participant_id"
    t.index ["remote_ip"], name: "index_api_requests_on_remote_ip"
    t.index ["user_agent"], name: "index_api_requests_on_user_agent"
  end

  create_table "api_sends", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "participant_id"
    t.integer "remote_actor_id"
    t.string "to_url"
    t.string "request_method"
    t.text "request_headers"
    t.text "request_object"
    t.integer "response_code"
    t.text "response_body"
    t.string "our_function"
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["our_function"], name: "index_api_sends_on_our_function"
    t.index ["participant_id"], name: "index_api_sends_on_participant_id"
    t.index ["remote_actor_id"], name: "index_api_sends_on_remote_actor_id"
  end

  create_table "authentications", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "participant_id"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ckeditor_assets", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.integer "assetable_id"
    t.string "assetable_type", limit: 30
    t.string "type", limit: 25
    t.string "guid", limit: 10
    t.integer "locale", limit: 1, default: 0
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "width"
    t.integer "height"
    t.index ["assetable_type", "assetable_id"], name: "fk_assetable"
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_assetable_type"
    t.index ["user_id"], name: "fk_user"
  end

  create_table "communities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "tagname"
    t.text "description"
    t.boolean "twitter_post", default: true
    t.string "twitter_username"
    t.string "twitter_oauth_token"
    t.string "twitter_oauth_secret"
    t.string "twitter_hash_tag"
    t.integer "tweet_approval_min", default: 1
    t.string "tweet_what", default: "roots"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.boolean "major", default: false
    t.boolean "more", default: false
    t.boolean "ungoals", default: false
    t.boolean "sustdev", default: false
    t.boolean "bold", default: false
    t.string "fullname", default: ""
    t.text "front_template"
    t.text "member_template"
    t.text "invite_template"
    t.text "import_template"
    t.text "signup_template"
    t.text "confirm_template"
    t.text "confirm_email_template"
    t.text "confirm_welcome_template"
    t.text "autotags"
    t.boolean "is_sub", default: false
    t.integer "sub_of"
    t.string "context", default: ""
    t.string "context_code", default: ""
    t.string "context2", default: ""
    t.string "context_code2", default: ""
    t.string "voice_of_humanity"
    t.string "voice_of_women"
    t.string "voice_of_men"
    t.string "voice_of_young"
    t.string "voice_of_middleage"
    t.string "voice_of_old"
    t.boolean "moderated", default: false
    t.boolean "active", default: true
    t.integer "conversation_id"
    t.string "visibility", default: "public"
    t.string "message_visibility", default: "public"
    t.integer "created_by"
    t.integer "administrator_id"
    t.string "who_add_members", default: "admin"
    t.index ["tagname"], name: "index_communities_on_tagname"
  end

  create_table "community_admins", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "community_id"
    t.integer "participant_id"
    t.boolean "active", default: true
    t.boolean "admin", default: false
    t.boolean "moderator", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "participant_id"], name: "index_community_admins_on_community_id_and_participant_id"
  end

  create_table "community_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "community_id"
    t.integer "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "item_id"], name: "index_community_items_on_community_id_and_item_id"
    t.index ["item_id", "community_id"], name: "index_community_items_on_item_id_and_community_id"
  end

  create_table "community_networks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "community_id"
    t.integer "network_id"
    t.integer "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "network_id"], name: "index_community_networks_on_community_id_and_network_id"
    t.index ["network_id", "community_id"], name: "index_community_networks_on_network_id_and_community_id"
  end

  create_table "community_participants", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "community_id"
    t.integer "participant_id"
    t.index ["community_id", "participant_id"], name: "index_community_participants_on_community_id_and_participant_id", unique: true
    t.index ["participant_id", "community_id"], name: "index_community_participants_on_participant_id_and_community_id", unique: true
  end

  create_table "conversation_communities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "conversation_id"
    t.integer "community_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "conversation_id"], name: "com_conv_ids"
    t.index ["conversation_id", "community_id"], name: "conv_com_ids"
  end

  create_table "conversations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "shortname"
    t.text "description"
    t.text "front_template"
    t.string "context", default: ""
    t.string "context_code", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "together_apart", default: "apart"
    t.boolean "active", default: true
    t.text "topics"
    t.string "default_topic"
    t.boolean "twocountry", default: false
    t.integer "twocountry_country1"
    t.integer "twocountry_country2"
    t.integer "twocountry_supporter1"
    t.integer "twocountry_supporter2"
    t.integer "twocountry_common"
    t.index ["context_code", "context"], name: "index_conversations_on_context_code_and_context"
    t.index ["name"], name: "index_conversations_on_name"
    t.index ["shortname"], name: "index_conversations_on_shortname"
  end

  create_table "dialog_admins", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dialog_id"
    t.integer "participant_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dialog_id", "participant_id"], name: "index_dialog_admins_on_dialog_id_and_participant_id"
  end

  create_table "dialog_groups", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dialog_id"
    t.integer "group_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "signup_template"
    t.text "confirm_template"
    t.text "confirm_email_template"
    t.text "confirm_welcome_template"
    t.datetime "apply_at"
    t.integer "apply_by", default: 0
    t.string "apply_status", default: ""
    t.integer "processed_by", default: 0
    t.index ["dialog_id", "group_id"], name: "index_dialog_groups_on_dialog_id_and_group_id"
    t.index ["group_id", "dialog_id"], name: "index_dialog_groups_on_group_id_and_dialog_id"
  end

  create_table "dialog_metamaps", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dialog_id"
    t.integer "metamap_id"
    t.integer "sortorder"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dialog_id", "metamap_id"], name: "index_dialog_metamaps_on_dialog_id_and_metamap_id"
    t.index ["metamap_id", "dialog_id"], name: "index_dialog_metamaps_on_metamap_id_and_dialog_id"
  end

  create_table "dialog_participants", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dialog_id"
    t.integer "participant_id"
    t.boolean "moderator", default: false
    t.boolean "active", default: true
    t.string "direct_email_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dialog_id", "participant_id"], name: "index_dialog_participants_on_dialog_id_and_participant_id"
    t.index ["direct_email_code"], name: "index_dialog_participants_on_direct_email_code", length: 20
    t.index ["participant_id", "dialog_id"], name: "index_dialog_participants_on_participant_id_and_dialog_id"
  end

  create_table "dialogs", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "shortdesc"
    t.text "instructions"
    t.text "coordinators"
    t.string "visibility"
    t.string "publishing"
    t.integer "max_voting_distribution"
    t.integer "max_characters"
    t.integer "max_words"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "shortname"
    t.integer "created_by"
    t.boolean "multigroup", default: false
    t.integer "group_id"
    t.string "openness"
    t.integer "max_mess_length"
    t.text "signup_template"
    t.text "front_template"
    t.text "confirm_template"
    t.text "confirm_email_template"
    t.text "confirm_welcome_template"
    t.text "member_template"
    t.text "list_template"
    t.string "metamap_vote_own"
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.text "default_message"
    t.boolean "required_message", default: true
    t.boolean "required_subject", default: true
    t.boolean "alt_logins", default: true
    t.integer "max_messages", default: 0
    t.string "new_message_title"
    t.boolean "allow_replies", default: true
    t.boolean "required_meta", default: true
    t.string "value_calc", default: "total"
    t.boolean "profiles_visible", default: true
    t.boolean "names_visible_voting", default: true
    t.boolean "names_visible_general", default: true
    t.boolean "in_voting_round", default: false
    t.boolean "posting_open", default: true
    t.boolean "voting_open", default: true
    t.integer "current_period"
    t.string "twitter_hash_tag"
    t.string "default_datetype", default: "fixed"
    t.string "default_datefixed", default: "month"
    t.date "default_datefrom"
    t.index ["name"], name: "index_dialogs_on_name", length: 30
    t.index ["shortname"], name: "index_dialogs_on_shortname", length: 20
  end

  create_table "emails", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "participant_id"
    t.integer "integer"
    t.string "context"
    t.string "string"
    t.boolean "sent", default: false
    t.datetime "sent_at"
    t.datetime "datetime"
    t.boolean "seen", default: false
    t.datetime "seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id", "id"], name: "index_emails_on_participant_id_and_id"
  end

  create_table "follows", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "following_id"
    t.integer "followed_id"
    t.boolean "mutual", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "int_ext", default: "int"
    t.string "following_fulluniq"
    t.string "followed_fulluniq"
    t.integer "followed_remote_actor_id"
    t.integer "following_remote_actor_id"
    t.boolean "accepted", default: false
    t.integer "accept_record_id"
    t.string "remote_reference"
    t.integer "api_request_id"
    t.index ["followed_fulluniq", "following_fulluniq"], name: "index_follows_on_followed_fulluniq_and_following_fulluniq", length: { followed_fulluniq: 30, following_fulluniq: 10 }
    t.index ["followed_id", "following_id"], name: "index_follows_on_followed_id_and_following_id"
    t.index ["following_fulluniq", "followed_fulluniq"], name: "index_follows_on_following_fulluniq_and_followed_fulluniq", length: { following_fulluniq: 30, followed_fulluniq: 10 }
    t.index ["following_id", "followed_id"], name: "index_follows_on_following_id_and_followed_id"
  end

  create_table "geoadmin1s", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "admin1uniq", limit: 15
    t.string "country_code", limit: 2
    t.string "admin1_code", limit: 10
    t.string "name"
    t.boolean "has_admin2s"
    t.index ["country_code", "admin1_code"], name: "admin1_code"
    t.index ["country_code", "name"], name: "geoadmin1s_name_index", length: { name: 20 }
  end

  create_table "geoadmin2s", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "admin2uniq", limit: 30
    t.string "country_code", limit: 2
    t.string "admin1_code", limit: 10
    t.string "admin2_code", limit: 15
    t.string "name"
    t.string "name_ascii"
    t.integer "geoname_id"
    t.string "admin1uniq", limit: 15
    t.index ["admin1uniq"], name: "admin1uniq"
    t.index ["country_code", "admin1_code", "admin2_code"], name: "admin2_code"
    t.index ["country_code", "name"], name: "geoadmin2s_name_index", length: { name: 20 }
    t.index ["geoname_id"], name: "geoname_id"
  end

  create_table "geocountries", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "iso", limit: 2
    t.string "iso3", limit: 3
    t.integer "isonum"
    t.string "fips", limit: 2
    t.string "name"
    t.string "capital"
    t.string "area"
    t.integer "population"
    t.string "continent", limit: 2
    t.string "tld", limit: 3
    t.string "currency_code", limit: 3
    t.string "currency_name"
    t.integer "phone"
    t.string "zip_format"
    t.string "zip_regex"
    t.string "languages"
    t.integer "geoname_id"
    t.string "neighbors"
    t.string "fips_equiv"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "extrasort", limit: 3
    t.index ["extrasort", "name"], name: "sortname"
    t.index ["iso"], name: "iso"
    t.index ["name"], name: "name"
  end

  create_table "geonames", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "asciiname"
    t.text "alternatenames"
    t.decimal "latitude", precision: 11, scale: 6
    t.decimal "longitude", precision: 11, scale: 6
    t.string "feature_class", limit: 1
    t.string "feature_code", limit: 10
    t.string "country_code", limit: 2
    t.string "cc2"
    t.string "admin1_code", limit: 20
    t.string "admin2_code", limit: 80
    t.string "admin3_code", limit: 20
    t.string "admin4_code", limit: 20
    t.bigint "population"
    t.integer "elevation"
    t.integer "gtopo30"
    t.string "timezone"
    t.date "modification_date"
    t.string "fclasscode", limit: 7
    t.index ["country_code", "admin1_code", "admin2_code"], name: "index_geonames_on_country_code_and_admin1_code_and_admin2_code"
    t.index ["feature_class", "feature_code"], name: "feature"
    t.index ["latitude"], name: "latitude"
    t.index ["longitude"], name: "longitude"
    t.index ["name"], name: "geonames_name_index", length: 30
  end

  create_table "group_metamaps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "group_id"
    t.integer "metamap_id"
    t.integer "sortorder"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "metamap_id"], name: "index_group_metamaps_on_dialog_id_and_metamap_id"
    t.index ["metamap_id", "group_id"], name: "index_group_metamaps_on_metamap_id_and_group_id"
  end

  create_table "group_participants", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "group_id"
    t.integer "participant_id"
    t.boolean "moderator", default: false
    t.boolean "active", default: true
    t.string "status", default: "active"
    t.string "direct_email_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["direct_email_code"], name: "index_group_participants_on_direct_email_code", length: 20
    t.index ["group_id", "participant_id"], name: "index_group_participants_on_group_id_and_participant_id"
    t.index ["participant_id", "group_id"], name: "index_group_participants_on_participant_id_and_group_id"
  end

  create_table "group_subtag_participants", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "group_subtag_id"
    t.integer "group_id"
    t.integer "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["group_subtag_id"], name: "index_group_subtag_participants_on_group_subtag_id"
    t.index ["participant_id"], name: "index_group_subtag_participants_on_participant_id"
  end

  create_table "group_subtags", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "group_id"
    t.string "tag", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "selfadd", default: true
    t.text "description"
    t.index ["group_id", "tag"], name: "index_group_subtags_on_group_id_and_tag"
  end

  create_table "groups", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "shortname"
    t.text "description"
    t.text "shortdesc"
    t.string "instructions"
    t.string "visibility", default: "public"
    t.string "openness"
    t.string "message_visibility", default: "public"
    t.boolean "moderation", default: false
    t.boolean "is_network", default: false
    t.boolean "is_global", default: false
    t.integer "owner"
    t.integer "group_participants_count", default: 0
    t.integer "items_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "twitter_post", default: true
    t.string "twitter_username"
    t.string "twitter_oauth_token"
    t.string "twitter_oauth_secret"
    t.string "twitter_hash_tag"
    t.boolean "has_mail_list", default: true
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.text "front_template"
    t.text "member_template"
    t.text "invite_template"
    t.text "import_template"
    t.text "signup_template"
    t.text "confirm_template"
    t.text "confirm_email_template"
    t.text "confirm_welcome_template"
    t.boolean "alt_logins", default: true
    t.boolean "required_meta", default: true
    t.integer "tweet_approval_min", default: 1
    t.string "tweet_what", default: "roots"
    t.boolean "tweet_subgroups", default: false
    t.index ["name"], name: "index_groups_on_name"
    t.index ["shortname"], name: "index_groups_on_shortname", length: 20
  end

  create_table "help_texts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "code"
    t.string "description"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_help_texts_on_code", length: 30
  end

  create_table "hub_admins", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "hub_id"
    t.integer "participant_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["hub_id", "participant_id"], name: "index_hub_admins_on_hub_id_and_participant_id"
  end

  create_table "hubs", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_hubs_on_name"
  end

  create_table "item_deliveries", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "item_id"
    t.integer "participant_id"
    t.string "context"
    t.datetime "sent_at"
    t.datetime "seen_at"
    t.index ["item_id", "participant_id"], name: "index_item_deliveries_on_item_id_and_participant_id"
    t.index ["participant_id", "item_id"], name: "index_item_deliveries_on_participant_id_and_item_id"
  end

  create_table "item_flags", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "item_id"
    t.integer "participant_id"
    t.text "comment"
    t.boolean "cleared", default: false
    t.integer "moderator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["item_id", "participant_id"], name: "index_item_flags_on_item_id_and_participant_id"
    t.index ["moderator_id", "item_id"], name: "index_item_flags_on_moderator_id_and_item_id"
    t.index ["participant_id", "item_id"], name: "index_item_flags_on_participant_id_and_item_id"
  end

  create_table "item_rating_summaries", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "item_id"
    t.string "summary_type", limit: 15
    t.integer "int_0_count", default: 0
    t.integer "int_1_count", default: 0
    t.integer "int_2_count", default: 0
    t.integer "int_3_count", default: 0
    t.integer "int_4_count", default: 0
    t.integer "int_count", default: 0
    t.integer "int_total", default: 0
    t.decimal "int_average", precision: 6, scale: 2, default: "0.0"
    t.integer "app_n3_count", default: 0
    t.integer "app_n2_count", default: 0
    t.integer "app_n1_count", default: 0
    t.integer "app_0_count", default: 0
    t.integer "app_p1_count", default: 0
    t.integer "app_p2_count", default: 0
    t.integer "app_p3_count", default: 0
    t.integer "app_count", default: 0
    t.integer "app_total", default: 0
    t.decimal "app_average", precision: 6, scale: 2, default: "0.0"
    t.decimal "value", precision: 6, scale: 2
    t.decimal "controversy", precision: 6, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["app_average"], name: "index_item_rating_summaries_on_app_average"
    t.index ["controversy"], name: "index_item_rating_summaries_on_controversy"
    t.index ["int_average"], name: "index_item_rating_summaries_on_int_average"
    t.index ["item_id"], name: "index_item_rating_summaries_on_item_id"
    t.index ["value"], name: "index_item_rating_summaries_on_value"
  end

  create_table "item_subscribes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "item_id"
    t.integer "participant_id"
    t.boolean "followed", default: true
    t.index ["item_id", "participant_id"], name: "index_item_subscribes_on_item_id_and_participant_id"
    t.index ["participant_id", "item_id"], name: "index_item_subscribes_on_participant_id_and_item_id"
  end

  create_table "item_thumbs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "original_url"
    t.string "our_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["original_url"], name: "index_item_thumbs_on_original_url", length: 35
  end

  create_table "items", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "item_type", default: "message"
    t.string "media_type", default: "text"
    t.string "int_ext", default: "int"
    t.integer "posted_by"
    t.integer "posted_by_remote_actor_id"
    t.integer "group_id"
    t.integer "dialog_id"
    t.integer "dialog_round_id"
    t.integer "conversation_id"
    t.integer "community_id"
    t.integer "community2_id"
    t.string "subject"
    t.integer "subject_id"
    t.boolean "promoted_to_forum"
    t.boolean "posted_to_forum", default: true
    t.string "election_area_type"
    t.string "moderation_status"
    t.datetime "moderated_at"
    t.string "moderated_by"
    t.text "short_content"
    t.text "html_content"
    t.text "xml_content"
    t.string "link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "approval", precision: 6, scale: 2, default: "0.0"
    t.decimal "interest", precision: 6, scale: 2, default: "0.0"
    t.decimal "value", precision: 6, scale: 2, default: "0.0"
    t.decimal "controversy", precision: 6, scale: 2, default: "0.0"
    t.text "oembed_response"
    t.text "embed_code"
    t.integer "thumb_id"
    t.boolean "has_picture", default: false
    t.string "posted_via", default: "web"
    t.integer "reply_to"
    t.boolean "is_first_in_thread"
    t.integer "first_in_thread"
    t.integer "old_message_id"
    t.boolean "is_flagged", default: false
    t.boolean "edit_locked", default: false
    t.integer "period_id"
    t.integer "first_in_thread_group_id"
    t.boolean "tweeted_user", default: false
    t.datetime "tweeted_user_at"
    t.boolean "tweeted_group", default: false
    t.datetime "tweeted_group_at"
    t.boolean "been_moderated", default: true
    t.boolean "censored", default: false
    t.string "geo_level"
    t.string "intra_com", default: "public"
    t.string "visible_com", default: "public"
    t.string "intra_conv", default: "public"
    t.boolean "outside_com_post", default: false
    t.text "outside_com_details"
    t.boolean "outside_conv_reply", default: false
    t.string "representing_com"
    t.string "together_apart", default: ""
    t.string "topic"
    t.string "wall_delivery", default: "public"
    t.boolean "wall_post", default: false
    t.string "comment_email_to", default: "author"
    t.string "remote_reference"
    t.text "received_json"
    t.integer "api_request_id"
    t.boolean "remote_delivery_done", default: true
    t.index ["conversation_id"], name: "index_items_on_conversation_id"
    t.index ["created_at"], name: "index_items_on_created_at"
    t.index ["dialog_id", "created_at"], name: "index_items_on_dialog_id_and_created_at"
    t.index ["first_in_thread", "id"], name: "index_items_on_first_in_thread_and_id"
    t.index ["geo_level", "id"], name: "index_items_on_geo_level_and_id", length: { geo_level: 10 }
    t.index ["group_id", "created_at"], name: "index_items_on_group_id_and_created_at"
    t.index ["old_message_id"], name: "index_items_on_old_message_id"
    t.index ["period_id", "id"], name: "index_items_on_period_id_and_id"
    t.index ["posted_by", "created_at"], name: "index_items_on_posted_by_and_created_at"
    t.index ["posted_by_remote_actor_id"], name: "index_items_on_posted_by_remote_actor_id"
    t.index ["remote_delivery_done"], name: "index_items_on_remote_delivery_done"
  end

  create_table "messages", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "from_participant_id"
    t.integer "from_remote_actor_id"
    t.integer "to_participant_id"
    t.integer "to_group_id"
    t.integer "to_remote_actor_id"
    t.integer "to_friend_id"
    t.integer "template_id"
    t.string "subject"
    t.text "message"
    t.string "sendmethod"
    t.boolean "sent"
    t.datetime "sent_at"
    t.integer "response_to_id"
    t.boolean "read_email"
    t.boolean "read_web"
    t.datetime "read_at"
    t.boolean "sender_delete"
    t.boolean "recipient_delete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "message_id"
    t.string "mail_template"
    t.integer "group_id"
    t.integer "dialog_id"
    t.boolean "email_sent", default: false
    t.datetime "email_sent_at"
    t.string "int_ext", default: "int"
    t.text "received_json"
    t.integer "api_request_id"
    t.string "remote_reference"
    t.index ["from_participant_id", "id"], name: "index_messages_on_from_participant_id_and_id"
    t.index ["from_remote_actor_id"], name: "index_messages_on_from_remote_actor_id"
    t.index ["message_id"], name: "index_messages_on_message_id", length: 30
    t.index ["to_participant_id", "id"], name: "index_messages_on_to_participant_id_and_id"
    t.index ["to_remote_actor_id"], name: "index_messages_on_to_remote_actor_id"
  end

  create_table "metamap_node_participants", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "metamap_id"
    t.integer "metamap_node_id"
    t.integer "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["metamap_id", "metamap_node_id"], name: "metamap_node"
    t.index ["metamap_node_id", "participant_id"], name: "node_particip"
    t.index ["participant_id", "metamap_node_id"], name: "particip_node"
  end

  create_table "metamap_nodes", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "metamap_id"
    t.string "name"
    t.string "name_as_group"
    t.integer "parent_id"
    t.text "description"
    t.string "sortorder"
    t.boolean "sumcat", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "binary_on", default: false
    t.index ["metamap_id", "sortorder"], name: "index_metamap_nodes_on_metamap_id_and_sortorder", length: { sortorder: 10 }
    t.index ["parent_id"], name: "index_metamap_nodes_on_parent_id"
  end

  create_table "metamaps", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "created_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "global_default", default: false
    t.boolean "binary", default: false
    t.index ["created_at"], name: "index_metamaps_on_created_at"
    t.index ["created_by"], name: "index_metamaps_on_created_by"
    t.index ["name"], name: "index_metamaps_on_name", length: 20
  end

  create_table "metro_areas", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "country_code"
    t.integer "population"
    t.integer "population_year"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["country_code", "name"], name: "index_metro_areas_on_country_code_and_name", length: { country_code: 1, name: 20 }
  end

  create_table "moons", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "mdate"
    t.string "topic"
    t.text "top_text"
    t.text "bottom_text"
    t.string "new_or_full", default: "new"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mtime", limit: 5, default: "12:00"
    t.boolean "mailing_sent", default: false
    t.index ["mdate"], name: "index_moons_on_mdate"
  end

  create_table "network_communities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "network_id"
    t.integer "community_id"
    t.integer "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "network_id"], name: "com_net_ids"
    t.index ["network_id", "community_id"], name: "net_com_ids"
  end

  create_table "networks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "communityarray"
    t.integer "age", default: 0
    t.integer "gender", default: 0
    t.integer "geo_level", default: 0
    t.string "geo_level_detail", default: ""
    t.string "geo_level_id", default: ""
    t.index ["created_by"], name: "created_by"
    t.index ["name"], name: "name"
  end

  create_table "participant_religions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "participant_id"
    t.integer "religion_id"
    t.string "religion_denomination"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id", "religion_id"], name: "index_participant_religions_on_participant_id_and_religion_id"
    t.index ["religion_id", "participant_id"], name: "index_participant_religions_on_religion_id_and_participant_id"
  end

  create_table "participants", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.text "self_description"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "city_uniq", limit: 128, default: ""
    t.string "admin2uniq", limit: 30
    t.string "county_code", limit: 15
    t.string "county_name"
    t.string "admin1uniq", limit: 15
    t.string "state_code", limit: 10
    t.string "state_name"
    t.string "country_code", limit: 2
    t.string "country_iso3", limit: 3, default: ""
    t.string "country_name"
    t.string "country_code2", limit: 2
    t.string "country2_iso3", limit: 3, default: ""
    t.string "country_name2"
    t.string "zip"
    t.string "phone"
    t.decimal "latitude", precision: 11, scale: 6
    t.decimal "longitude", precision: 11, scale: 6
    t.string "timezone"
    t.decimal "timezone_offset", precision: 5, scale: 1
    t.string "metropolitan_area"
    t.integer "metro_area_id"
    t.string "bioregion"
    t.integer "bioregion_id"
    t.string "faith_tradition"
    t.integer "faith_tradition_id"
    t.string "political"
    t.integer "political_id"
    t.string "status"
    t.string "email", default: "", null: false
    t.string "old_email"
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.string "password_salt", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "remember_token"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean "sysadmin", default: false
    t.integer "items_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "fb_uid"
    t.string "fb_link"
    t.string "visibility", default: "visible_to_all"
    t.string "wall_visibility", default: "all"
    t.boolean "item_to_forum", default: true
    t.boolean "twitter_post", default: true
    t.string "twitter_username"
    t.string "twitter_oauth_token"
    t.string "twitter_oauth_secret"
    t.string "forum_email", default: "never"
    t.string "group_email", default: "instant"
    t.string "subgroup_email", default: "instant"
    t.string "private_email", default: "instant"
    t.string "system_email", default: "instant"
    t.string "mycom_email", default: "daily"
    t.string "othercom_email", default: "daily"
    t.boolean "no_email", default: false
    t.string "no_email_reason", default: ""
    t.string "direct_email_code"
    t.boolean "has_participated", default: false
    t.integer "old_user_id"
    t.text "forum_settings"
    t.string "last_url"
    t.string "handle"
    t.string "authentication_token"
    t.boolean "new_signup", default: true
    t.boolean "dialog_pop_shown", default: false
    t.boolean "required_entered", default: false
    t.integer "last_group_id"
    t.integer "last_dialog_id"
    t.string "provider"
    t.string "uid"
    t.string "disc_interface", default: "simple"
    t.string "picture_file_name"
    t.string "picture_content_type"
    t.integer "picture_file_size"
    t.datetime "picture_updated_at"
    t.boolean "indigenous", default: false
    t.boolean "other_minority", default: false
    t.boolean "veteran", default: false
    t.boolean "interfaith", default: false
    t.boolean "refugee", default: false
    t.text "check_boxes"
    t.text "explanation"
    t.string "google_uid", default: ""
    t.string "account_uniq", limit: 12, default: ""
    t.string "account_uniq_full", limit: 64, default: ""
    t.text "private_key"
    t.text "public_key"
    t.index ["account_uniq"], name: "index_participants_on_account_uniq"
    t.index ["confirmation_token"], name: "index_participants_on_confirmation_token", unique: true
    t.index ["country_code", "state_code", "city"], name: "index_participants_on_country_code_and_state_code_and_city", length: { city: 20 }
    t.index ["direct_email_code"], name: "index_participants_on_direct_email_code", length: 20
    t.index ["email"], name: "index_participants_on_email", unique: true
    t.index ["last_name", "first_name"], name: "index_participants_on_last_name_and_first_name", length: 20
    t.index ["old_user_id"], name: "index_participants_on_old_user_id"
    t.index ["reset_password_token"], name: "index_participants_on_reset_password_token", unique: true
  end

  create_table "periods", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "startdate"
    t.date "enddate"
    t.date "endposting"
    t.date "endrating"
    t.string "name"
    t.string "shortname"
    t.string "group_dialog", default: "dialog"
    t.integer "group_id"
    t.integer "dialog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.text "shortdesc"
    t.text "instructions"
    t.text "metamaps"
    t.boolean "metamaps_frozen", default: false
    t.integer "max_characters"
    t.integer "max_words"
    t.string "metamap_vote_own"
    t.text "default_message"
    t.boolean "required_message", default: true
    t.boolean "required_subject", default: true
    t.integer "max_messages", default: 0
    t.string "new_message_title"
    t.boolean "allow_replies", default: true
    t.boolean "required_meta", default: true
    t.string "value_calc", default: "total"
    t.boolean "profiles_visible", default: true
    t.boolean "names_visible_voting", default: true
    t.boolean "names_visible_general", default: true
    t.boolean "in_voting_round", default: false
    t.boolean "posting_open", default: true
    t.boolean "voting_open", default: true
    t.integer "sort_metamap_id"
    t.string "sort_order", default: "date"
    t.string "crosstalk", default: "none"
    t.integer "period_number", default: 0
    t.text "result", limit: 16777215
    t.index ["dialog_id", "startdate"], name: "index_periods_on_dialog_id_and_startdate"
    t.index ["group_id", "startdate"], name: "index_periods_on_group_id_and_startdate"
  end

  create_table "photos", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "participant_id"
    t.text "caption"
    t.string "filename"
    t.integer "filesize"
    t.integer "width"
    t.integer "height"
    t.string "filetype", limit: 3
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["participant_id"], name: "index_photos_on_participant_id"
  end

  create_table "ratings", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "item_id"
    t.integer "participant_id"
    t.integer "remote_actor_id"
    t.string "rating_type", limit: 15
    t.integer "group_id"
    t.integer "dialog_id"
    t.integer "dialog_round_id"
    t.integer "approval"
    t.integer "interest"
    t.integer "importance"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "period_id"
    t.integer "conversation_id"
    t.index ["group_id", "id"], name: "index_ratings_on_group_id_and_id"
    t.index ["item_id", "id"], name: "index_ratings_on_item_id_and_id"
    t.index ["participant_id", "id"], name: "index_ratings_on_participant_id_and_id"
    t.index ["remote_actor_id", "id"], name: "index_ratings_on_remote_actor_id_and_id"
  end

  create_table "religions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "shortname"
    t.string "subdiv", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_religions_on_name", length: 35
  end

  create_table "remote_actors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "account"
    t.string "account_url"
    t.text "json_got"
    t.string "username"
    t.string "name"
    t.text "summary"
    t.string "inbox_url"
    t.string "outbox_url"
    t.string "icon_url"
    t.string "image_url"
    t.text "public_key"
    t.datetime "last_fetch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account"], name: "index_remote_actors_on_account", length: 30
    t.index ["account_url"], name: "index_remote_actors_on_account_url"
    t.index ["name"], name: "index_remote_actors_on_name"
  end

  create_table "sys_data", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "cur_moon_id"
    t.string "moon_new_or_full", default: "new"
    t.datetime "moon_startdate"
    t.datetime "moon_enddate"
    t.string "together_apart", default: "apart"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "taggings", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context"
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, length: { taggable_type: 15, context: 15, tagger_type: 15 }
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", length: { taggable_type: 15, context: 15 }
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", length: { taggable_type: 20, context: 20 }
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "templates", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "section", limit: 20
    t.string "mail_web", limit: 4
    t.string "title"
    t.text "html_body"
    t.text "footer"
    t.integer "dialog_id"
    t.integer "group_id"
    t.integer "round_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dialog_id"], name: "index_templates_on_dialog_id"
    t.index ["group_id"], name: "index_templates_on_group_id"
    t.index ["round_id"], name: "index_templates_on_round_id"
    t.index ["section"], name: "index_templates_on_section"
  end

end
