require "active_support/core_ext/integer/time"

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
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = BASEDOMAIN   

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "intermix_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  ### ActionMailer Config
  config.action_mailer.default_url_options = { :host => BASEDOMAIN }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  #config.action_mailer.delivery_method = :sendmail
  config.action_mailer.delivery_method   = :postmark

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  # changes in syntax: https://github.com/smartinez87/exception_notification
  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[InterMix Bug] ",
      :sender_address => %{"Exception Notifier" <questions@intermix.org>},
      :exception_recipients => %w{ffunch@gmail.com}
    }  

end

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
