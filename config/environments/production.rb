#if request and request.domain == 'cr8.com'
if (ENV and ENV['SYS_MODE'] and ENV['SYS_MODE'] == 'staging') or (`hostname` =~ /ovh.net/) or (File.dirname(__FILE__) =~ /cr8/) or (ENV['HTTP_HOST'] =~ /cr8/ ) or (`hostname` =~ /sirius/ )
  BASEDOMAIN = 'intermix.cr8.com'
  ROOTDOMAIN = 'intermix.cr8.com'
  MAILDOMAIN = 'trantor.cr8.com'
else
  BASEDOMAIN = 'go.intermix.org'
  ROOTDOMAIN = 'intermix.org'
  MAILDOMAIN = 'intermix.org'
end

DATADIR = '/home/apps/intermix/shared/data'

Intermix::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  ### ActionMailer Config
  config.action_mailer.default_url_options = { :host => BASEDOMAIN }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  #config.action_mailer.delivery_method = :sendmail
  config.action_mailer.delivery_method   = :postmark

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  #config.assets.compress = true
  config.assets.compress = false

  # fallback to assets pipeline if a precompiled asset is missed
  #config.assets.compile = true
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Enable serving of images, stylesheets, and javascripts from an asset server
  #if `hostname` =~ /ovh.net/
    config.action_controller.asset_host = BASEDOMAIN   
  #else
  #  config.action_controller.asset_host = "http://go.intermix.org"
  #end

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  config.middleware.use ExceptionNotifier,
    :email_prefix => "[InterMix Bug] ",
    :sender_address => %{"Exception Notifier" <noreply@cr8.com>},
    :exception_recipients => %w{ffunch@gmail.com}

    config.assets.precompile += Ckeditor.assets
  
end


Paperclip.options[:command_path] = "/usr/bin"
