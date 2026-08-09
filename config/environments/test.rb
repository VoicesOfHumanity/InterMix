BASEDOMAIN = 'intermix.test'
ROOTDOMAIN = 'intermix.test'
DATADIR = '/Users/ffunch/_websites/intermix/data'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none  # Rails 7.1: was `false` (deprecated; removed in 7.2)

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end

# Constants that production.rb / development.rb define but test.rb was missing —
# any spec that renders a layout uses VOL_LOGO (og:image), so define it here too.
VOL_LOGO = "/images/data/photos/7/67.jpg" unless defined?(VOL_LOGO)

# check_group_and_dialog runs before nearly every signed-in action and falls back
# to GLOBAL_GROUP_ID when the request has no group subdomain, so request specs for
# any such controller need these two.
GLOBAL_GROUP_ID = 20 unless defined?(GLOBAL_GROUP_ID)
VISITOR_ID = 2634 unless defined?(VISITOR_ID)

# The "front" layout links to the standing conversations by id, so any request
# spec that renders it needs all of these. The values are only ever interpolated
# into hrefs; development.rb's numbering is used here.
INT_CONVERSATION_ID = 3 unless defined?(INT_CONVERSATION_ID)
INT_CONVERSATION_CODE = 'The_Nations' unless defined?(INT_CONVERSATION_CODE)
CITY_CONVERSATION_ID = 4 unless defined?(CITY_CONVERSATION_ID)
CITY_CONVERSATION_CODE = 'The_Cities' unless defined?(CITY_CONVERSATION_CODE)
UNGOALS_CONVERSATION_ID = 5 unless defined?(UNGOALS_CONVERSATION_ID)
UNGOALS_CONVERSATION_CODE = 'The_UN_Goals' unless defined?(UNGOALS_CONVERSATION_CODE)
ISRAEL_PALESTINE_CONV_ID = 6 unless defined?(ISRAEL_PALESTINE_CONV_ID)
ISRAEL_PALESTINE_CONV_CODE = 'MidEastpeace' unless defined?(ISRAEL_PALESTINE_CONV_CODE)
RELIGIONS_CONVERSATION_ID = 7 unless defined?(RELIGIONS_CONVERSATION_ID)
RELIGIONS_CONVERSATION_CODE = 'The_Religions' unless defined?(RELIGIONS_CONVERSATION_CODE)
GENDER_CONVERSATION_ID = 8 unless defined?(GENDER_CONVERSATION_ID)
GENDER_CONVERSATION_CODE = 'The_Genders' unless defined?(GENDER_CONVERSATION_CODE)
GENERATION_CONVERSATION_ID = 9 unless defined?(GENERATION_CONVERSATION_ID)
GENERATION_CONVERSATION_CODE = 'The_Generations' unless defined?(GENERATION_CONVERSATION_CODE)

MAILDOMAIN = 'trantor.cr8.com'

TWITTER_CONSUMER_KEY = 'Ew8NROMK7YbDa3XIph6gA'   # = API key. And this is for the Posting app, not the Login app
TWITTER_CONSUMER_SECRET = 'ghQ41Vu377BAh3oVRACpKdYzeUo5SJardQunvALkj8'

FACEBOOK_APP_ID          = '1406266652976637'
FACEBOOK_API_SECRET      = 'ec6fc05777932b40f23434bdbdadabec'