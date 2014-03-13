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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140313120319) do

  create_table "authentications", :force => true do |t|
    t.integer  "participant_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ckeditor_assets", :force => true do |t|
    t.string   "data_file_name",                                 :null => false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    :limit => 30
    t.string   "type",              :limit => 25
    t.string   "guid",              :limit => 10
    t.integer  "locale",            :limit => 1,  :default => 0
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width"
    t.integer  "height"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], :name => "fk_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], :name => "idx_assetable_type"
  add_index "ckeditor_assets", ["user_id"], :name => "fk_user"

  create_table "dialog_admins", :force => true do |t|
    t.integer  "dialog_id"
    t.integer  "participant_id"
    t.boolean  "active",         :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dialog_admins", ["dialog_id", "participant_id"], :name => "index_dialog_admins_on_dialog_id_and_participant_id"

  create_table "dialog_groups", :force => true do |t|
    t.integer  "dialog_id"
    t.integer  "group_id"
    t.boolean  "active",                   :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "signup_template"
    t.text     "confirm_template"
    t.text     "confirm_email_template"
    t.text     "confirm_welcome_template"
    t.datetime "apply_at"
    t.integer  "apply_by",                 :default => 0
    t.string   "apply_status",             :default => ""
    t.integer  "processed_by",             :default => 0
  end

  add_index "dialog_groups", ["dialog_id", "group_id"], :name => "index_dialog_groups_on_dialog_id_and_group_id"
  add_index "dialog_groups", ["group_id", "dialog_id"], :name => "index_dialog_groups_on_group_id_and_dialog_id"

  create_table "dialog_metamaps", :force => true do |t|
    t.integer  "dialog_id"
    t.integer  "metamap_id"
    t.integer  "sortorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dialog_metamaps", ["dialog_id", "metamap_id"], :name => "index_dialog_metamaps_on_dialog_id_and_metamap_id"
  add_index "dialog_metamaps", ["metamap_id", "dialog_id"], :name => "index_dialog_metamaps_on_metamap_id_and_dialog_id"

  create_table "dialog_participants", :force => true do |t|
    t.integer  "dialog_id"
    t.integer  "participant_id"
    t.boolean  "moderator",         :default => false
    t.boolean  "active",            :default => true
    t.string   "direct_email_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dialog_participants", ["dialog_id", "participant_id"], :name => "index_dialog_participants_on_dialog_id_and_participant_id"
  add_index "dialog_participants", ["direct_email_code"], :name => "index_dialog_participants_on_direct_email_code", :length => {"direct_email_code"=>20}
  add_index "dialog_participants", ["participant_id", "dialog_id"], :name => "index_dialog_participants_on_participant_id_and_dialog_id"

  create_table "dialogs", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "shortdesc"
    t.text     "instructions"
    t.text     "coordinators"
    t.string   "visibility"
    t.string   "publishing"
    t.integer  "max_voting_distribution"
    t.integer  "max_characters"
    t.integer  "max_words"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "shortname"
    t.integer  "created_by"
    t.boolean  "multigroup",               :default => false
    t.integer  "group_id"
    t.string   "openness"
    t.integer  "max_mess_length"
    t.text     "signup_template"
    t.text     "front_template"
    t.text     "confirm_template"
    t.text     "confirm_email_template"
    t.text     "confirm_welcome_template"
    t.text     "member_template"
    t.text     "list_template"
    t.string   "metamap_vote_own"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.text     "default_message"
    t.boolean  "required_message",         :default => true
    t.boolean  "required_subject",         :default => true
    t.boolean  "alt_logins",               :default => true
    t.integer  "max_messages",             :default => 0
    t.string   "new_message_title"
    t.boolean  "allow_replies",            :default => true
    t.boolean  "required_meta",            :default => true
    t.string   "value_calc",               :default => "total"
    t.boolean  "profiles_visible",         :default => true
    t.boolean  "names_visible_voting",     :default => true
    t.boolean  "names_visible_general",    :default => true
    t.boolean  "in_voting_round",          :default => false
    t.boolean  "posting_open",             :default => true
    t.boolean  "voting_open",              :default => true
    t.integer  "current_period"
    t.string   "twitter_hash_tag"
  end

  add_index "dialogs", ["name"], :name => "index_dialogs_on_name", :length => {"name"=>30}
  add_index "dialogs", ["shortname"], :name => "index_dialogs_on_shortname", :length => {"shortname"=>20}

  create_table "follows", :force => true do |t|
    t.integer  "following_id"
    t.integer  "followed_id"
    t.boolean  "mutual",       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "follows", ["followed_id", "following_id"], :name => "index_follows_on_followed_id_and_following_id"
  add_index "follows", ["following_id", "followed_id"], :name => "index_follows_on_following_id_and_followed_id"

  create_table "geoadmin1s", :force => true do |t|
    t.string  "admin1uniq",   :limit => 15
    t.string  "country_code", :limit => 2
    t.string  "admin1_code",  :limit => 10
    t.string  "name"
    t.boolean "has_admin2s"
  end

  add_index "geoadmin1s", ["country_code", "admin1_code"], :name => "admin1_code"
  add_index "geoadmin1s", ["country_code", "name"], :name => "geoadmin1s_name_index", :length => {"country_code"=>nil, "name"=>20}

  create_table "geoadmin2s", :force => true do |t|
    t.string  "admin2uniq",   :limit => 30
    t.string  "country_code", :limit => 2
    t.string  "admin1_code",  :limit => 10
    t.string  "admin2_code",  :limit => 15
    t.string  "name"
    t.string  "name_ascii"
    t.integer "geoname_id"
    t.string  "admin1uniq",   :limit => 15
  end

  add_index "geoadmin2s", ["admin1uniq"], :name => "admin1uniq"
  add_index "geoadmin2s", ["country_code", "admin1_code", "admin2_code"], :name => "admin2_code"
  add_index "geoadmin2s", ["country_code", "name"], :name => "geoadmin2s_name_index", :length => {"country_code"=>nil, "name"=>20}
  add_index "geoadmin2s", ["geoname_id"], :name => "geoname_id"

  create_table "geocountries", :force => true do |t|
    t.string   "iso",           :limit => 2
    t.string   "iso3",          :limit => 3
    t.integer  "isonum"
    t.string   "fips",          :limit => 2
    t.string   "name"
    t.string   "capital"
    t.string   "area"
    t.integer  "population"
    t.string   "continent",     :limit => 2
    t.string   "tld",           :limit => 3
    t.string   "currency_code", :limit => 3
    t.string   "currency_name"
    t.integer  "phone"
    t.string   "zip_format"
    t.string   "zip_regex"
    t.string   "languages"
    t.integer  "geoname_id"
    t.string   "neighbors"
    t.string   "fips_equiv"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extrasort",     :limit => 3
  end

  add_index "geocountries", ["extrasort", "name"], :name => "sortname"
  add_index "geocountries", ["iso"], :name => "iso"
  add_index "geocountries", ["name"], :name => "name"

  create_table "group_metamaps", :force => true do |t|
    t.integer  "group_id"
    t.integer  "metamap_id"
    t.integer  "sortorder"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "group_metamaps", ["group_id", "metamap_id"], :name => "index_group_metamaps_on_dialog_id_and_metamap_id"
  add_index "group_metamaps", ["metamap_id", "group_id"], :name => "index_group_metamaps_on_metamap_id_and_group_id"

  create_table "group_participants", :force => true do |t|
    t.integer  "group_id"
    t.integer  "participant_id"
    t.boolean  "moderator",         :default => false
    t.boolean  "active",            :default => true
    t.string   "status",            :default => "active"
    t.string   "direct_email_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "group_participants", ["direct_email_code"], :name => "index_group_participants_on_direct_email_code", :length => {"direct_email_code"=>20}
  add_index "group_participants", ["group_id", "participant_id"], :name => "index_group_participants_on_group_id_and_participant_id"
  add_index "group_participants", ["participant_id", "group_id"], :name => "index_group_participants_on_participant_id_and_group_id"

  create_table "group_subtag_participants", :force => true do |t|
    t.integer  "group_subtag_id"
    t.integer  "group_id"
    t.integer  "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "group_subtag_participants", ["group_subtag_id"], :name => "index_group_subtag_participants_on_group_subtag_id"
  add_index "group_subtag_participants", ["participant_id"], :name => "index_group_subtag_participants_on_participant_id"

  create_table "group_subtags", :force => true do |t|
    t.integer  "group_id"
    t.string   "tag",         :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "selfadd",                   :default => true
    t.text     "description"
  end

  add_index "group_subtags", ["group_id", "tag"], :name => "index_group_subtags_on_group_id_and_tag"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "shortname"
    t.text     "description"
    t.text     "shortdesc"
    t.string   "instructions"
    t.string   "visibility",               :default => "public"
    t.string   "openness"
    t.string   "message_visibility",       :default => "public"
    t.boolean  "moderation",               :default => false
    t.boolean  "is_network",               :default => false
    t.integer  "owner"
    t.integer  "group_participants_count", :default => 0
    t.integer  "items_count",              :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "twitter_post",             :default => true
    t.string   "twitter_username"
    t.string   "twitter_oauth_token"
    t.string   "twitter_oauth_secret"
    t.string   "twitter_hash_tag"
    t.boolean  "has_mail_list",            :default => true
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.text     "front_template"
    t.text     "member_template"
    t.text     "invite_template"
    t.text     "import_template"
    t.text     "signup_template"
    t.text     "confirm_template"
    t.text     "confirm_email_template"
    t.text     "confirm_welcome_template"
    t.boolean  "alt_logins",               :default => true
    t.boolean  "required_meta",            :default => true
    t.integer  "tweet_approval_min",       :default => 1
    t.string   "tweet_what",               :default => "roots"
    t.boolean  "tweet_subgroups",          :default => false
  end

  add_index "groups", ["name"], :name => "index_groups_on_name"
  add_index "groups", ["shortname"], :name => "index_groups_on_shortname", :length => {"shortname"=>20}

  create_table "help_texts", :force => true do |t|
    t.string   "code"
    t.string   "description"
    t.text     "text"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "help_texts", ["code"], :name => "index_help_texts_on_code", :length => {"code"=>30}

  create_table "hub_admins", :force => true do |t|
    t.integer  "hub_id"
    t.integer  "participant_id"
    t.boolean  "active",         :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hub_admins", ["hub_id", "participant_id"], :name => "index_hub_admins_on_hub_id_and_participant_id"

  create_table "hubs", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hubs", ["name"], :name => "index_hubs_on_name"

  create_table "item_deliveries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_flags", :force => true do |t|
    t.integer  "item_id"
    t.integer  "participant_id"
    t.text     "comment"
    t.boolean  "cleared",        :default => false
    t.integer  "moderator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_flags", ["item_id", "participant_id"], :name => "index_item_flags_on_item_id_and_participant_id"
  add_index "item_flags", ["moderator_id", "item_id"], :name => "index_item_flags_on_moderator_id_and_item_id"
  add_index "item_flags", ["participant_id", "item_id"], :name => "index_item_flags_on_participant_id_and_item_id"

  create_table "item_rating_summaries", :force => true do |t|
    t.integer  "item_id"
    t.string   "summary_type", :limit => 15
    t.integer  "int_0_count",                                              :default => 0
    t.integer  "int_1_count",                                              :default => 0
    t.integer  "int_2_count",                                              :default => 0
    t.integer  "int_3_count",                                              :default => 0
    t.integer  "int_4_count",                                              :default => 0
    t.integer  "int_count",                                                :default => 0
    t.integer  "int_total",                                                :default => 0
    t.decimal  "int_average",                :precision => 6, :scale => 2, :default => 0.0
    t.integer  "app_n3_count",                                             :default => 0
    t.integer  "app_n2_count",                                             :default => 0
    t.integer  "app_n1_count",                                             :default => 0
    t.integer  "app_0_count",                                              :default => 0
    t.integer  "app_p1_count",                                             :default => 0
    t.integer  "app_p2_count",                                             :default => 0
    t.integer  "app_p3_count",                                             :default => 0
    t.integer  "app_count",                                                :default => 0
    t.integer  "app_total",                                                :default => 0
    t.decimal  "app_average",                :precision => 6, :scale => 2, :default => 0.0
    t.decimal  "value",                      :precision => 6, :scale => 2
    t.decimal  "controversy",                :precision => 6, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_rating_summaries", ["app_average"], :name => "index_item_rating_summaries_on_app_average"
  add_index "item_rating_summaries", ["controversy"], :name => "index_item_rating_summaries_on_controversy"
  add_index "item_rating_summaries", ["int_average"], :name => "index_item_rating_summaries_on_int_average"
  add_index "item_rating_summaries", ["item_id"], :name => "index_item_rating_summaries_on_item_id"
  add_index "item_rating_summaries", ["value"], :name => "index_item_rating_summaries_on_value"

  create_table "items", :force => true do |t|
    t.string   "item_type",                                              :default => "message"
    t.string   "media_type",                                             :default => "text"
    t.integer  "posted_by"
    t.integer  "group_id"
    t.integer  "dialog_id"
    t.integer  "dialog_round_id"
    t.string   "subject"
    t.integer  "subject_id"
    t.boolean  "promoted_to_forum"
    t.boolean  "posted_to_forum",                                        :default => true
    t.string   "election_area_type"
    t.string   "moderation_status"
    t.datetime "moderated_at"
    t.string   "moderated_by"
    t.text     "short_content"
    t.text     "html_content"
    t.text     "xml_content"
    t.string   "link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "approval",                 :precision => 6, :scale => 2, :default => 0.0
    t.decimal  "interest",                 :precision => 6, :scale => 2, :default => 0.0
    t.decimal  "value",                    :precision => 6, :scale => 2, :default => 0.0
    t.decimal  "controversy",              :precision => 6, :scale => 2, :default => 0.0
    t.text     "oembed_response"
    t.text     "embed_code"
    t.boolean  "has_picture",                                            :default => false
    t.string   "posted_via",                                             :default => "web"
    t.integer  "reply_to"
    t.boolean  "is_first_in_thread"
    t.integer  "first_in_thread"
    t.integer  "old_message_id"
    t.boolean  "is_flagged",                                             :default => false
    t.boolean  "edit_locked",                                            :default => false
    t.integer  "period_id"
    t.integer  "first_in_thread_group_id"
    t.boolean  "tweeted_user",                                           :default => false
    t.datetime "tweeted_user_at"
    t.boolean  "tweeted_group",                                          :default => false
    t.datetime "tweeted_group_at"
  end

  add_index "items", ["created_at"], :name => "index_items_on_created_at"
  add_index "items", ["dialog_id", "created_at"], :name => "index_items_on_dialog_id_and_created_at"
  add_index "items", ["first_in_thread", "id"], :name => "index_items_on_first_in_thread_and_id"
  add_index "items", ["group_id", "created_at"], :name => "index_items_on_group_id_and_created_at"
  add_index "items", ["old_message_id"], :name => "index_items_on_old_message_id"
  add_index "items", ["period_id", "id"], :name => "index_items_on_period_id_and_id"
  add_index "items", ["posted_by", "created_at"], :name => "index_items_on_posted_by_and_created_at"

  create_table "messages", :force => true do |t|
    t.integer  "from_participant_id"
    t.integer  "to_participant_id"
    t.integer  "to_group_id"
    t.integer  "template_id"
    t.string   "subject"
    t.text     "message"
    t.string   "sendmethod"
    t.boolean  "sent"
    t.datetime "sent_at"
    t.integer  "response_to_id"
    t.boolean  "read_email"
    t.boolean  "read_web"
    t.datetime "read_at"
    t.boolean  "sender_delete"
    t.boolean  "recipient_delete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "message_id"
    t.string   "mail_template"
    t.integer  "group_id"
    t.integer  "dialog_id"
    t.boolean  "email_sent",          :default => false
    t.datetime "email_sent_at"
  end

  add_index "messages", ["from_participant_id", "id"], :name => "index_messages_on_from_participant_id_and_id"
  add_index "messages", ["message_id"], :name => "index_messages_on_message_id", :length => {"message_id"=>30}
  add_index "messages", ["to_participant_id", "id"], :name => "index_messages_on_to_participant_id_and_id"

  create_table "metamap_node_participants", :force => true do |t|
    t.integer  "metamap_id"
    t.integer  "metamap_node_id"
    t.integer  "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metamap_node_participants", ["metamap_id", "metamap_node_id"], :name => "metamap_node"
  add_index "metamap_node_participants", ["metamap_node_id", "participant_id"], :name => "node_particip"
  add_index "metamap_node_participants", ["participant_id", "metamap_node_id"], :name => "particip_node"

  create_table "metamap_nodes", :force => true do |t|
    t.integer  "metamap_id"
    t.string   "name"
    t.string   "name_as_group"
    t.integer  "parent_id"
    t.text     "description"
    t.string   "sortorder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metamap_nodes", ["metamap_id", "sortorder"], :name => "index_metamap_nodes_on_metamap_id_and_sortorder", :length => {"metamap_id"=>nil, "sortorder"=>10}
  add_index "metamap_nodes", ["parent_id"], :name => "index_metamap_nodes_on_parent_id"

  create_table "metamaps", :force => true do |t|
    t.string   "name"
    t.integer  "created_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "global_default", :default => false
  end

  add_index "metamaps", ["created_at"], :name => "index_metamaps_on_created_at"
  add_index "metamaps", ["created_by"], :name => "index_metamaps_on_created_by"
  add_index "metamaps", ["name"], :name => "index_metamaps_on_name", :length => {"name"=>20}

  create_table "metro_areas", :force => true do |t|
    t.string   "name"
    t.string   "country_code"
    t.integer  "population"
    t.integer  "population_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metro_areas", ["country_code", "name"], :name => "index_metro_areas_on_country_code_and_name", :length => {"country_code"=>1, "name"=>20}

  create_table "participants", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.text     "self_description"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "admin2uniq",             :limit => 30
    t.string   "county_code",            :limit => 15
    t.string   "county_name"
    t.string   "admin1uniq",             :limit => 15
    t.string   "state_code",             :limit => 10
    t.string   "state_name"
    t.string   "country_code",           :limit => 2
    t.string   "country_name"
    t.string   "zip"
    t.string   "phone"
    t.decimal  "latitude",                              :precision => 11, :scale => 6
    t.decimal  "longitude",                             :precision => 11, :scale => 6
    t.string   "timezone"
    t.decimal  "timezone_offset",                       :precision => 5,  :scale => 1
    t.string   "metropolitan_area"
    t.integer  "metro_area_id"
    t.string   "bioregion"
    t.integer  "bioregion_id"
    t.string   "faith_tradition"
    t.integer  "faith_tradition_id"
    t.string   "political"
    t.integer  "political_id"
    t.string   "status"
    t.string   "email",                                                                :default => "",               :null => false
    t.string   "old_email"
    t.string   "encrypted_password",     :limit => 128,                                :default => "",               :null => false
    t.string   "password_salt",                                                        :default => "",               :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "sysadmin",                                                             :default => false
    t.integer  "items_count",                                                          :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fb_uid"
    t.string   "fb_link"
    t.string   "visibility",                                                           :default => "visible_to_all"
    t.string   "wall_visibility",                                                      :default => "all"
    t.boolean  "item_to_forum",                                                        :default => true
    t.boolean  "twitter_post",                                                         :default => true
    t.string   "twitter_username"
    t.string   "twitter_oauth_token"
    t.string   "twitter_oauth_secret"
    t.string   "forum_email",                                                          :default => "never"
    t.string   "group_email",                                                          :default => "instant"
    t.string   "subgroup_email",                                                       :default => "instant"
    t.string   "private_email",                                                        :default => "instant"
    t.string   "system_email",                                                         :default => "instant"
    t.boolean  "no_email",                                                             :default => false
    t.string   "direct_email_code"
    t.boolean  "has_participated",                                                     :default => false
    t.integer  "old_user_id"
    t.text     "forum_settings"
    t.string   "last_url"
    t.string   "handle"
    t.string   "authentication_token"
    t.boolean  "new_signup",                                                           :default => true
    t.boolean  "dialog_pop_shown",                                                     :default => false
    t.boolean  "required_entered",                                                     :default => false
    t.integer  "last_group_id"
    t.integer  "last_dialog_id"
  end

  add_index "participants", ["confirmation_token"], :name => "index_participants_on_confirmation_token", :unique => true
  add_index "participants", ["country_code", "state_code", "city"], :name => "index_participants_on_country_code_and_state_code_and_city", :length => {"country_code"=>nil, "state_code"=>nil, "city"=>20}
  add_index "participants", ["direct_email_code"], :name => "index_participants_on_direct_email_code", :length => {"direct_email_code"=>20}
  add_index "participants", ["email"], :name => "index_participants_on_email", :unique => true
  add_index "participants", ["last_name", "first_name"], :name => "index_participants_on_last_name_and_first_name", :length => {"last_name"=>20, "first_name"=>20}
  add_index "participants", ["old_user_id"], :name => "index_participants_on_old_user_id"
  add_index "participants", ["reset_password_token"], :name => "index_participants_on_reset_password_token", :unique => true

  create_table "periods", :force => true do |t|
    t.date     "startdate"
    t.date     "enddate"
    t.date     "endposting"
    t.date     "endrating"
    t.string   "name"
    t.string   "shortname"
    t.string   "group_dialog",          :default => "dialog"
    t.integer  "group_id"
    t.integer  "dialog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.text     "shortdesc"
    t.text     "instructions"
    t.text     "metamaps"
    t.boolean  "metamaps_frozen",       :default => false
    t.integer  "max_characters"
    t.integer  "max_words"
    t.string   "metamap_vote_own"
    t.text     "default_message"
    t.boolean  "required_message",      :default => true
    t.boolean  "required_subject",      :default => true
    t.integer  "max_messages",          :default => 0
    t.string   "new_message_title"
    t.boolean  "allow_replies",         :default => true
    t.boolean  "required_meta",         :default => true
    t.string   "value_calc",            :default => "total"
    t.boolean  "profiles_visible",      :default => true
    t.boolean  "names_visible_voting",  :default => true
    t.boolean  "names_visible_general", :default => true
    t.boolean  "in_voting_round",       :default => false
    t.boolean  "posting_open",          :default => true
    t.boolean  "voting_open",           :default => true
    t.integer  "sort_metamap_id"
    t.string   "sort_order",            :default => "date"
  end

  add_index "periods", ["dialog_id", "startdate"], :name => "index_periods_on_dialog_id_and_startdate"
  add_index "periods", ["group_id", "startdate"], :name => "index_periods_on_group_id_and_startdate"

  create_table "photos", :force => true do |t|
    t.integer  "participant_id"
    t.text     "caption"
    t.string   "filename"
    t.integer  "filesize"
    t.integer  "width"
    t.integer  "height"
    t.string   "filetype",       :limit => 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "photos", ["participant_id"], :name => "index_photos_on_participant_id"

  create_table "ratings", :force => true do |t|
    t.integer  "item_id"
    t.integer  "participant_id"
    t.string   "rating_type",     :limit => 15
    t.integer  "group_id"
    t.integer  "dialog_id"
    t.integer  "dialog_round_id"
    t.integer  "approval"
    t.integer  "interest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "period_id"
  end

  add_index "ratings", ["group_id", "id"], :name => "index_ratings_on_group_id_and_id"
  add_index "ratings", ["item_id", "id"], :name => "index_ratings_on_item_id_and_id"
  add_index "ratings", ["participant_id", "id"], :name => "index_ratings_on_participant_id_and_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context", :length => {"taggable_id"=>nil, "taggable_type"=>15, "context"=>20}

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "templates", :force => true do |t|
    t.string   "name"
    t.string   "section",    :limit => 20
    t.string   "mail_web",   :limit => 4
    t.string   "title"
    t.text     "html_body"
    t.text     "footer"
    t.integer  "dialog_id"
    t.integer  "group_id"
    t.integer  "round_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "templates", ["dialog_id"], :name => "index_templates_on_dialog_id"
  add_index "templates", ["group_id"], :name => "index_templates_on_group_id"
  add_index "templates", ["round_id"], :name => "index_templates_on_round_id"
  add_index "templates", ["section"], :name => "index_templates_on_section"

end
