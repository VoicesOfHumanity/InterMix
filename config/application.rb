# encoding: utf-8

Encoding.default_external = Encoding::UTF_8

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Intermix
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    #config.action_view.javascript_expansions[:defaults] = %w(jquery-1.4.2.min jquery-ui-1.8.6.custom.min ui.selectmenu.js rails)
    config.action_view.javascript_expansions[:defaults] = %w(https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js ui.selectmenu.js rails)
    
    #-- This is for ckeditor
    config.autoload_paths += %W( #{config.root}/app/models/ckeditor )
    
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
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
GROUP_OPENNESS_TEXT = {'open'=>'Open to join','open_to_apply'=>'Open to applications','by_invitation_only'=>'By invitation only','private'=>'Closed/Private'}
EMAIL_PREFS = ['instant','daily','never']
EMAIL_PREFS_TEXT = {'instant'=>'E-mail each one right away','daily'=>'E-mail in a daily batch','never'=>'Never e-mail'}
ITEM_TYPES = ['message']
RATING_TYPES = ['AllRatings','ElectionRating']
SECTIONS = ['home','forum','wall','profile']
MEDIA_TYPES = ['text','picture','video','audio','link']
METAMAP_VOTE_OWN = ['mainly', 'only', 'never']
METAMAP_VOTE_OWN_TEXT = {'mainly'=>"Primarily vote on own category's posts", 'only'=>"Only vote on own category's posts", 'never'=>"Can't vote on own category's posts"}
SYSTEM_SENDER = 'noreply@intermix.org'

# These are in localsettings.rb
#TWITTER_CONSUMER_KEY = 'xxxxxx'   # = API key. And this is for the Posting app, not the Login app
#TWITTER_CONSUMER_SECRET = 'xxxxxx'
#
#FACEBOOK_APP_ID          = 'xxxxxx'
#FACEBOOK_API_SECRET      = 'xxxxxx'



