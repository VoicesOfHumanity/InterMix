require "active_support/core_ext/integer/time"

if (ENV and ENV['SYS_MODE'] and ENV['SYS_MODE'] == 'staging') or (`hostname` =~ /ovh.net/) or (File.dirname(__FILE__) =~ /cr8/) or (ENV['HTTP_HOST'] =~ /cr8/ ) or (`hostname` =~ /sirius/ )
  BASEDOMAIN = 'intermix.cr8.com'
  ROOTDOMAIN = 'intermix.cr8.com'
  MAILDOMAIN = 'trantor.cr8.com'
  FACEBOOK_APP_ID          = '604196779657027'
  FACEBOOK_API_SECRET      = '03a98fc919e2ea25970367510d0c9b01'
  VOL_LOGO = "/images/data/photos/7/67.jpg"
  INT_CONVERSATION_ID = 1
  INT_CONVERSATION_CODE = 'The_Nations'
  CITY_CONVERSATION_ID = 5
  CITY_CONVERSATION_CODE = 'The_Cities'
  UNGOALS_CONVERSATION_ID = 4
  UNGOALS_CONVERSATION_CODE = 'The_UN_Goals'
  ISRAEL_PALESTINE_CONV_ID = 6
  ISRAEL_PALESTINE_CONV_CODE = 'MidEastpeace'
  RELIGIONS_CONVERSATION_ID = 7
  RELIGIONS_CONVERSATION_CODE = 'The_Religions'
  GENDER_CONVERSATION_ID = 8
  GENDER_CONVERSATION_CODE = 'The_Genders'
  GENERATION_CONVERSATION_ID = 9
  GENERATION_CONVERSATION_CODE = 'The_Generations'
  VISITOR_ID = 2634
else
  BASEDOMAIN = 'voh.intermix.org'
  ROOTDOMAIN = 'intermix.org'
  MAILDOMAIN = 'intermix.org'
  FACEBOOK_APP_ID          = '151526481561013'
  FACEBOOK_API_SECRET      = '3653366f2b6d4778e09db3d666d1fedf'
  VOL_LOGO = "/images/data/photos/7/67.jpg"
  INT_CONVERSATION_ID = 2
  INT_CONVERSATION_CODE = 'The_Nations'
  CITY_CONVERSATION_ID = 3
  CITY_CONVERSATION_CODE = 'The_Cities'
  UNGOALS_CONVERSATION_ID = 1
  UNGOALS_CONVERSATION_CODE = 'The_UN_Goals'
  ISRAEL_PALESTINE_CONV_ID = 4
  ISRAEL_PALESTINE_CONV_CODE = 'MidEastpeace'
  RELIGIONS_CONVERSATION_ID = 5
  RELIGIONS_CONVERSATION_CODE = 'The_Religions'
  GENDER_CONVERSATION_ID = 6
  GENDER_CONVERSATION_CODE = 'The_Genders'
  GENERATION_CONVERSATION_ID = 7
  GENERATION_CONVERSATION_CODE = 'The_Generations'
  VISITOR_ID = 3399
end

DATADIR = '/home/apps/intermix/shared/data'

#logger                                         = Logger.new(STDOUT)
#logger.level                                   = Logger::INFO
#RAILS_DEFAULT_LOGGER                           = logger
#ActiveRecord::Base.logger                      = logger
#ActionController::Base.logger                  = logger

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  config.require_master_key = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  #config.assets.compile = false
  config.assets.compile = true
  
  config.assets.precompile += Ckeditor.assets

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and javascripts from an asset server
  #if `hostname` =~ /ovh.net/
  config.action_controller.asset_host = BASEDOMAIN   
  #else
  #  config.action_controller.asset_host = "http://go.intermix.org"
  #end
  
  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )
  

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true
  
  # To avoid SameSite warnings in Firefox. Probably only works in Rails 6 and up
  config.action_dispatch.cookies_same_site_protection = :lax

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true
  # config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  #config.log_formatter = ::Logger::Formatter.new
  config.log_level = :info

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  
  ### ActionMailer Config
  config.action_mailer.default_url_options = { :host => BASEDOMAIN }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  #config.action_mailer.delivery_method = :sendmail
  config.action_mailer.delivery_method   = :postmark
  
  # changes in syntax: https://github.com/smartinez87/exception_notification
  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[InterMix Bug] ",
      :sender_address => %{"Exception Notifier" <questions@intermix.org>},
      :exception_recipients => %w{ffunch@gmail.com}
    }   
  
end

Paperclip.options[:command_path] = "/usr/bin"

TWITTER_CONSUMER_KEY = 'Ew8NROMK7YbDa3XIph6gA'   # = API key. And this is for the Posting app, not the Login app
TWITTER_CONSUMER_SECRET = 'ghQ41Vu377BAh3oVRACpKdYzeUo5SJardQunvALkj8'

GLOBAL_GROUP_ID = 20
VOH_DISCUSSION_ID = 7