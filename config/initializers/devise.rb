# Use this hook to configure devise mailer, warden hooks and so forth. The first
# four configuration values can also be set straight in your models.

#require 'openid/store/filesystem'

Devise.setup do |config|

  # >3.2
  #config.secret_key = 'c1a45168a4e56497e08fb6e3f57cfa8a2376a0a98dcd1a4a44b1917ed878996a96a5df5218daa3dc3d8b6f97a109a73085e4a8e80edebc97319ee701d9e5bcf6'
  config.secret_key = 'bc4f113616c84d6d45371ff06d4bcf0d61d8c4878b0e680ddb64d607ac0aba35d86f59dec60eb1bec6f67fd56632e66745920b6cbecf32bd56adf34b19181687'

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in DeviseMailer.
  config.mailer_sender = "webmaster@intermix.org"

  # Configure the class responsible to send e-mails.
  # config.mailer = "Devise::Mailer"

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  # config.authentication_keys = [ :email ]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [ :email ]

  # Tell if authentication through request.params is enabled. True by default.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Basic Auth is enabled. False by default.
  # config.http_authenticatable = false

  # If http headers should be returned for AJAX requests. True by default.
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. "Application" by default.
  # config.http_authentication_realm = "Application"

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 10. If
  # using other encryptors, it sets how many times you want the password re-encrypted.
  config.stretches = 10

  # ==> Configuration for :confirmable
  # The time you want to give your user to confirm his account. During this time
  # he will be able to access your application without confirming. Default is 0.days
  # When confirm_within is zero, the user won't be able to sign in without confirming.
  # You can use this to let your user access some features of your application
  # without confirming the account, but blocking it after a certain period
  # (ie 2 days).
  # config.confirm_within = 2.days

  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # config.remember_for = 2.weeks

  # If true, a valid remember token can be re-used between multiple browsers.
  # config.remember_across_browsers = true

  # If true, extends the user's remember period when remembered via cookie.
  # config.extend_remember_period = false

  # ==> Configuration for :validatable
  # Range for password length. Default is 6..20.
  # config.password_length = 6..20
  config.password_length = 4..20

  # Regex to use to validate the email address
  # config.email_regexp = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  # config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  # config.lock_strategy = :failed_attempts

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  # config.unlock_strategy = :both

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  # config.maximum_attempts = 20

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  # config.unlock_in = 1.hour

  # ==> Configuration for :encryptable
  # Allow you to use another encryption algorithm besides bcrypt (default). You can use
  # :sha1, :sha512 or encryptors from others authentication tools as :clearance_sha1,
  # :authlogic_sha512 (then you should set stretches above to 20 for default behavior)
  # and :restful_authentication_sha1 (then you should set stretches to 10, and copy
  # REST_AUTH_SITE_KEY to pepper)
  # config.encryptor = :sha512

  # Setup a pepper to generate the encrypted password.
  # config.pepper = "9d0ef1e9e1cd27f55dc10eafe3e925e21af58d4c27bc986b6dea6cb8e37e934330ab608028bc9597371ec03f24d06c5a496a81b11370b075afc2bc6520a28fd1"

  # ==> Configuration for :token_authenticatable
  # Defines name of the authentication token params key
  # http://yekmer.posterous.com/single-access-token-using-devise
  #config.token_authentication_key = :auth_token

  # If true, authentication through token does not store user in session and needs
  # to be supplied on each request. Useful if you are using the token as API token.
  # config.stateless_token = false

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = false

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  # config.default_scope = :user

  # Configure sign_out behavior.
  # Sign_out action can be scoped (i.e. /users/sign_out affects only :user scope).
  # The default is true, which means any logout action will sign out all active scopes.
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html, should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The :"*/*" format below is required to match Internet Explorer requests.
  # config.navigational_formats = [:"*/*", :html]

  # The default HTTP method used to sign out a resource. Default is :get.
  # config.sign_out_via = :get

  #config.oauth :facebook, '151526481561013', '3653366f2b6d4778e09db3d666d1fedf', 
  #  :site => 'https://graph.facebook.com/',
  #  :authorize_path => '/oauth/authorize',
  #  :access_token_path => '/oauth/access_token',
  #  :scope => %w(email)

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting
  # up on your models and hooks.
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', :scope => 'user,public_repo'
  if Rails.env.development?
    config.omniauth :facebook, "1406266652976637","ec6fc05777932b40f23434bdbdadabec", { provider_ignores_state: true, }
  elsif (ENV and ENV['SYS_MODE'] and ENV['SYS_MODE'] == 'staging') or (`hostname` =~ /ovh.net/) or (File.dirname(__FILE__) =~ /cr8/) or (ENV['HTTP_HOST'] =~ /cr8/ ) or (`hostname` =~ /sirius/ )
    config.omniauth :facebook, "604196779657027", "03a98fc919e2ea25970367510d0c9b01"
  else
    config.omniauth :facebook, "151526481561013", "3653366f2b6d4778e09db3d666d1fedf"
  end
  
  config.omniauth :google_oauth2, "347530640667-ofi2v3lo7ijkmrjkn608ob2581moupek.apps.googleusercontent.com", "EisPs0whNq-803uqnXQLI7je", {
      scope: "userinfo.email"
  }
  
  #config.omniauth :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
  #OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if Rails.env.development? 

  # Don't know what this is for, but it insisted on being set
  config.reset_password_within = 24.hours

  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
  # config.warden do |manager|
  #   manager.failure_app   = AnotherApp
  #   manager.intercept_401 = false
  #   manager.default_strategies(:scope => :user).unshift :some_external_strategy
  # end
  # https://github.com/hassox/warden/wiki/callbacks
  Warden::Manager.after_set_user do |user, auth, opts|
    #-- What happens when a user is authenticated. Maybe better to put stuff in after_sign_in_path_for in application controller
    #Rails.logger.info("devise#after_set_user")
    #if not user.status
    #  auth.logout
    #  throw(:warden, :message => "The account has no status. Something is wrong.")
    #elsif user.status == 'unconfirmed'
    #  #user.status = 'active'
    #  #user.save
    #  #auth.logout
    #  #throw(:warden, :message => "Please confirm your account by click on the link in the e-mail we sent you")
    #elsif user.status != 'active'
    #  auth.logout
    #  throw(:warden, :message => "User not active")
    #end
  end
  
  # http://rubydoc.info/github/hassox/warden/master/Warden/Hooks
  Warden::Manager.before_logout do |user, auth, opts|
  # session variables weren't available for some reason. Using this instead: https://github.com/hassox/warden/wiki/Authenticated-Session-Data
    begin
      auth.session[:dialog_id] = nil if auth and auth.session and auth.session[:dialog_id]
      auth.session[:dialog_name] = nil if auth and auth.session and auth.session[:dialog_name]
      auth.session[:group_id] = nil if auth and auth.session and auth.session[:group_id]
      auth.session[:group_name] = nil if auth and auth.session and auth.session[:group_name]
    rescue
    end
  end
  
end
