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
    #config.active_record.raise_in_transactional_callbacks = true
    
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
    config.action_controller.permit_all_parameters = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    
    # This is temporary, because I can't find out to make the parameters work for groupsx   
    #config.action_controller.permit_all_parameters = true
    
    # rack-cors configuration. https://github.com/cyu/rack-cors
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        #origins '*'
        origins 'http://intermix.test:3000','http://intermix.test:3002','https://intermix.test:3000', 'https://localhost:3000', 'http://intermix.cr8.com','http://voh.intermix.cr8.com','https://intermix.org','https://voh.intermix.org'
        resource '*', :headers => :any, :methods => [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end
    
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

DEFAULT_COMMUNITIES = {
  'climateaction' => "SDG13: Climate Action: combat climate change",
  'commons' => "Commons movement",
  'coops' => "Cooperatives",
  'disabled' => "Disabled",
  'genderequality' => "SDG05: Gender equality: empower all women and girls",
  'globaljustice' => "Global Justice Movement",
  'gr8transition' => "Great Transition: big systemic changes are needed",
  'indigenous' => "Indigenous peoples",
  'interfaith' => "Interfaith movement",
  'labor' => "Labor movement",
  'lgbtq' => "Lesbian, Gay, Bi, Trans, Queer",
  'nonviolence' => "Nonviolent Action",
  'nuclear_disarm' => "Nuclear Disarmament",
  'minority' => "Other disadvantaged minorities",
  'peace' => "Peace with general and complete disarmament",
  'refugees' => "Refugees, asylees, illegal immigrants",
  'savechildren' => "Save the children",
  'the_poor' => "The Poor",
  'un_goals' => "UN Goals",
  'veterans' => "Veterans",
  'voh' => "Voices of Humanity supporters",
  
  'humanrights' => "Human Rights: UN Universal Declaration of Human Rights",
  'cedaw' => "Convention on the Elimination of all Forms of Discrimination Against Women",
  
  'sdgs' => "UN Sustainable Development Goals",
  'endpoverty' => "SDG01: End poverty in all its forms everywhere",
  'endhunger' => "SDG02: End hunger and promote sustainable agriculture",
  'goodhealth' => "SDG03: Good health for all at all ages",
  'goodeducation' => "SDG04: Good education: inclusive, equitable quality education for all",
  'cleanwater' => "SDG06: Clean water: sustainable clean water and sanitation for all",
  'renewablenergy' => "SDG07: Renewable energy: affordable, reliable, sustainable energy for all",
  'goodjobs' => "SDG08: Good jobs and sustainable development for all",
  'infrastructure' => "SDG09: Better infrastructure: innovative and resilient economic underpinning",
  'moreequality' => "SDG10: More equality: reverse the trend toward economic inequality",
  'bettercities' => "SDG11: Better Cities: inclusive, safe, resilient and sustainable urban areas",
  'simplifying' => "SDG12: Simplifying: do more and better with less",
  'protectoceans' => "SDG14: Protecting the oceans",
  'protecttheland' => "SDG15: Protecting land resources, biodiversity",
  'safeforall' => "SDG16: Peace and justice: end violence and corruption",
  'sdgpartners' => "SDG17: SDG partnerships: organize across the silos"
}
GLOBAL_COMMUNITIES = [
  'climateaction','commons','coops','disabled','genderequality','globaljustice','gr8transition','indigenous',
  'interfaith','labor','lgbtq','nonviolence','nuclear_disarm','minority','peace','refugees',
  'savechildren','the_poor','un_goals','veterans','voh' 
]
UNGOAL_COMMUNITIES = [
  'un_goals','peace','nuclear_disarm','humanrights','cedaw'
]
SUSTDEV_COMMUNITIES = [
  'sdgs','endpoverty','endhunger','goodhealth','goodeducation',
  'genderequality','cleanwater','renewablenergy','goodjobs','infrastructure','moreequality','bettercities',
  'simplifying','climateaction','protectoceans','protecttheland','safeforall','sdgpartners'
]
BOLD_COMMUNITIES = ['un_goals','sdgs']


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

GEO_LEVELS = {1 => 'city', 2 => 'county', 3 => 'metro', 4 => 'state', 5 => 'nation', 6 => 'planet'}
GEO_LEVEL_DESC = {'city' => "My city/town", 'county' => 'My county', 'metro' => "My metro region", "state" => "State/province", "nation" => "My nation", "earth" => "Planet Earth"}

# These are in localsettings.rb
#TWITTER_CONSUMER_KEY = 'xxxxxx'   # = API key. And this is for the Posting app, not the Login app
#TWITTER_CONSUMER_SECRET = 'xxxxxx'
#
#FACEBOOK_APP_ID          = 'xxxxxx'
#FACEBOOK_API_SECRET      = 'xxxxxx'

BITLY_USERNAME = 'intermix2'
BITLY_TOKEN = 'c9d06623cb928bca6977ae80bbdb1a4cc676309c'

#EMBEDLY_API_KEY = '69a93eaedc814b13ad46aa4952e75107'

VOH_DISCUSSION_ID = 4

# New moons: http://rubyslipper.ca/ruby-slipper-astrology/2014/10/newfull-moons-eclipses-2015
MOONS = {
  '2016-03-08_2017-06-23' => "March 8, 2016 - June 23, 2017",
  '2017-06-23_2017-07-23' => "June 23 - July 23, 2017",
  '2017-07-23_2017-08-21' => "July 23 - Aug 21, 2017",
  '2017-08-21_2017-09-20' => "Aug 21 - Sep 20, 2017",
  '2017-09-20_2017-10-19' => "Sep20 - Oct 19, 2017",
  '2017-10-19_2017-11-18' => "Oct 19 - Nov 18, 2017",
  '2017-11-18_2017-12-18' => "Nov 18 - Dec 18, 2017",
  '2017-12-18_2018-01-16' => "Dec 18, 2017 - Jan 18, 2018",
  '2018-01-16_2018-02-15' => "Jan 18 - Feb 15, 2018",
  '2018-02-15_2018-03-17' => "Feb 15 - Mar 17, 2018",
  '2018-03-17_2018-04-15' => "Mar 17 - Apr 15, 2018",
  '2018-04-15_2018-05-15' => "Apr 15 - May 15, 2018",
  '2018-05-15_2018-06-13' => "May 15 - Jun 13, 2018",
  '2018-06-13_2018-07-13' => "Jun 13 - Jul 13, 2018",
  '2018-07-13_2018-08-11' => "Jul 13 - Aug 11, 2018",
  '2018-08-11_2018-09-09' => "Aug 11 - Sep 9, 2018",
  '2018-09-09_2018-10-08' => "Sep 9 - Oct 8, 2018",
  '2018-10-08_2018-11-07' => "Oct 8 - Nov 7, 2018",
  '2018-11-07_2018-12-07' => "Nov 7 - Dec 7, 2018"
}
