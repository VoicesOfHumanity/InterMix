Intermix::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  ### ActionMailer Config
  config.action_mailer.default_url_options = { :host => 'intermix.dev' }
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

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  
end

#SYSTEM_SENDER = "noreply@intermix.cr8.com"

if File.dirname(__FILE__) =~ /_websites/
  BASEDOMAIN = 'intermix.dev'
  ROOTDOMAIN = 'intermix.dev'
  DATADIR = '/Users/ffunch/_websites/intermix/data'
else
  BASEDOMAIN = 'intermix.cr8.com'
  ROOTDOMAIN = 'intermix.cr8.com'
  DATADIR = '/home/apps/intermix/shared/data'
end
MAILDOMAIN = 'trantor.cr8.com'

#Paperclip.options[:command_path] = "/opt/local/bin"

TWITTER_CONSUMER_KEY = 'Ew8NROMK7YbDa3XIph6gA'   # = API key. And this is for the Posting app, not the Login app
TWITTER_CONSUMER_SECRET = 'ghQ41Vu377BAh3oVRACpKdYzeUo5SJardQunvALkj8'

FACEBOOK_APP_ID          = '1406266652976637'
FACEBOOK_API_SECRET      = 'ec6fc05777932b40f23434bdbdadabec'


