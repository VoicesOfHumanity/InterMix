require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Intermix
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    #-- This is for ckeditor
    config.autoload_paths += %W( #{config.root}/app/models/ckeditor )
    
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    #-- Using postmark for mailing
    config.action_mailer.delivery_method   = :postmark
    config.action_mailer.postmark_settings = { :api_key => "cc26728f-ff0c-403f-9c4a-be1b0c92d8bb" }

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true
    
    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    #config.active_record.whitelist_attributes = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    
  end
end

PARTICIPANT_STATUSES = ['unconfirmed','active','inactive','never-contact','disallowed']
PARTICIPANT_VISIBILITY = ['visible_to_all','visible_to_group_members']
PARTICIPANT_VISIBILITY_TEXT = {'visible_to_all'=>'Visible to all', 'visible_to_group_members'=>'Visible only to members of my groups'}

#-- Participant's setting for how visible their wall is
PARTICIPANT_WALL_VISIBILITY = ['all','groups&friends','friends']
PARTICIPANT_WALL_VISIBILITY_TEXT = {'all'=>'Visible to all','groups&friends'=>'Visible only to friends and other group members','friends'=>'Visible only to friends'}

GROUP_VISIBILITY = ['private','public']
GROUP_VISIBILITY_TEXT = {'private'=>'Private, unlisted', 'public'=>'Public, visible to all'}
GROUP_OPENNESS = ['open','open_to_apply','by_invitation_only','private']
GROUP_OPENNESS_TEXT = {'open'=>'open to join','open_to_apply'=>'apply to join','by_invitation_only'=>'by invitation','private'=>'closed/private'}
GROUP_MESSAGE_VISIBILITY = ['private','public']
GROUP_MESSAGE_VISIBILITY_TEXT = {'private'=>"private: non-members can't visit and see messages",'public'=>"public: non-members can visit the group and see messages"}

GROUP_PARTICIPANT_STATUSES = ['active', 'pending', 'invited', 'applied', 'denied', 'blocked']
GROUP_PARTICIPANT_STATUSES_TEXT = {'active'=>"Active group membership", 'pending'=>"Joined, but not yet active. Probably didn't yet confirm email.", 'invited'=>"Has been invited as a member, but has not yet accepted.", 'applied'=>"Has applied to become a member. Not yet approved.", 'denied'=>"Membership not accepted", 'blocked'=>"Not allowed in this group"}

CROSSTALK_OPTIONS = ['','gender','gender1','age','age1'] 
CROSSTALK_OPTIONS_TEXT = {''=>'No Crosstalk','gender'=>'Gender Crosstalk','gender1'=>'Gender Crosstalk 1st round','age'=>'Age Crosstalk','age1'=>'Age Crosstalk 1st round'}

EMAIL_PREFS = ['instant','daily','weekly','never']
EMAIL_PREFS_TEXT = {'instant'=>'E-mail each one right away','daily'=>'E-mail in a daily batch','weekly'=>'E-mail in a weekly batch','never'=>'Never e-mail'}
ITEM_TYPES = ['message']
RATING_TYPES = ['AllRatings','ElectionRating']
SECTIONS = ['home','forum','wall','profile']
MEDIA_TYPES = ['text','picture','video','audio','link']
METAMAP_VOTE_OWN = ['mainly', 'only', 'never']
METAMAP_VOTE_OWN_TEXT = {'mainly'=>"Primarily vote on own category's posts", 'only'=>"Only vote on own category's posts", 'never'=>"Can't vote on own category's posts"}
DIALOG_GROUP_STATUS = ['','apply','approved','denied']
DIALOG_GROUP_STATUS_TEXT = {''=>'','apply'=>'applied','approved'=>'approved','denied'=>'denied'}
SYSTEM_SENDER = 'questions@intermix.org'

MAIL_SYSTEM = 'postmark'   # postmark or system

GEO_LEVELS = {1 => 'city', 2 => 'metro', 3 => 'state', 4 => 'nation', 5 => 'planet'}
GEO_LEVEL_DESC = {'city' => "My city/town", 'metro' => "My metro region", "state" => "My state/province", "nation" => "My nation", "earth" => "Planet Earth"}

# These are in localsettings.rb
#TWITTER_CONSUMER_KEY = 'xxxxxx'   # = API key. And this is for the Posting app, not the Login app
#TWITTER_CONSUMER_SECRET = 'xxxxxx'
#
#FACEBOOK_APP_ID          = 'xxxxxx'
#FACEBOOK_API_SECRET      = 'xxxxxx'

BITLY_USERNAME = 'intermix2'
BITLY_TOKEN = 'c9d06623cb928bca6977ae80bbdb1a4cc676309c'
