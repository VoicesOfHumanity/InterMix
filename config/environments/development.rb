require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

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

  config.force_ssl = true
  
  config.hosts << "intermix.test"

end

if File.dirname(__FILE__) =~ /_websites/
  BASEDOMAIN = 'intermix.test:3002'
  ROOTDOMAIN = 'intermix.test'
  DATADIR = '/Users/ffunch/_websites/intermix/data'
  GLOBAL_GROUP_ID = 22
  VISITOR_ID = 1895
else
  BASEDOMAIN = 'voh.intermix.cr8.com'
  ROOTDOMAIN = 'intermix.cr8.com'
  DATADIR = '/home/apps/intermix/shared/data'
  GLOBAL_GROUP_ID = 20
  VISITOR_ID = 2634
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

ISRAEL_PALESTINE_CONV_ID = 6
ISRAEL_PALESTINE_CONV_CODE = 'MidEastpeace'

RELIGIONS_CONVERSATION_ID = 7
RELIGIONS_CONVERSATION_CODE = 'The_Religions'

GENDER_CONVERSATION_ID = 8
GENDER_CONVERSATION_CODE = 'The_Genders'

GENERATION_CONVERSATION_ID = 9
GENERATION_CONVERSATION_CODE = 'The_Generations'


