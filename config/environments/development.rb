Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  ### ActionMailer Config
  config.action_mailer.default_url_options = { :host => 'intermix.test' }
  if true
    config.action_mailer.delivery_method   = :postmark
    #config.action_mailer.postmark_settings = { :api_key => "cc26728f-ff0c-403f-9c4a-be1b0c92d8bb" }
    #config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      :address => "mail.worldtrans.org",
      :port => 25,
      :domain => "xxx.intermix.org",
      :authentication => :login,
      :user_name => "xxxxx",
      :password => "xxxx",
      :enable_starttls_auto => false
    }
  end
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  
  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  #config.active_record.auto_explain_threshold_in_seconds = 0.5
  
  #config.web_console.automount = true
  
  config.force_ssl = true
  
end

#SYSTEM_SENDER = "noreply@intermix.cr8.com"

if File.dirname(__FILE__) =~ /_websites/
  BASEDOMAIN = 'intermix.test:3002'
  ROOTDOMAIN = 'intermix.test'
  DATADIR = '/Users/ffunch/_websites/intermix/data'
  GLOBAL_GROUP_ID = 22
else
  BASEDOMAIN = 'voh.intermix.cr8.com'
  ROOTDOMAIN = 'intermix.cr8.com'
  DATADIR = '/home/apps/intermix/shared/data'
  GLOBAL_GROUP_ID = 20
end
MAILDOMAIN = 'trantor.cr8.com'

#Paperclip.options[:command_path] = "/opt/local/bin"

TWITTER_CONSUMER_KEY = 'Ew8NROMK7YbDa3XIph6gA'   # = API key. And this is for the Posting app, not the Login app
TWITTER_CONSUMER_SECRET = 'ghQ41Vu377BAh3oVRACpKdYzeUo5SJardQunvALkj8'

FACEBOOK_APP_ID          = '1406266652976637'
FACEBOOK_API_SECRET      = 'ec6fc05777932b40f23434bdbdadabec'

VOH_DISCUSSION_ID = 5
VOL_LOGO = "/images/data/dialogs/logos/7/original_blacksheep1S.jpg"

INT_CONVERSATION_ID = 3
INT_CONVERSATION_CODE = 'The_Nations'

CITY_CONVERSATION_ID = 4
CITY_CONVERSATION_CODE = 'The_Cities'

UNGOALS_CONVERSATION_ID = 5
UNGOALS_CONVERSATION_CODE = 'The_UN_Goals'

