source 'http://rubygems.org'

ruby '2.7.7'

#gem 'rails', '~> 3.2'
#gem 'rails', '~> 4.2'
gem 'rails', '~> 5.2.3'
gem 'rake'

gem 'activerecord-session_store'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'rack-cors', :require => 'rack/cors'

gem "openssl"

gem 'mysql2'
#gem 'mysql2', '~> 0.3.18'
#gem 'mysql2', '~> 0.4.2'

gem 'jquery-rails'
gem 'jquery-ui-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
#gem 'capistrano', '~> 2.15'
#gem 'capistrano-rails'

# To use debugger
# gem 'ruby-debug'

# to do benchmarking
gem 'ruby-prof'

#gem 'devise', :git => "http://github.com/plataformatec/devise.git"
#gem 'devise', '3.0.2'
gem 'devise'
#gem "oauth2"
gem "omniauth"
#gem "oa-oauth", :require => "omniauth/oauth"
gem 'omniauth-openid'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'
#gem 'omniauth-google_apps'
gem "omniauth-rails_csrf_protection"

gem 'rest-graph'

gem 'rmagick', :require => "rmagick"
gem 'acts-as-taggable-on'
#gem 'simple_captcha'
#gem 'ckeditor', '3.4.2.pre'
gem 'ckeditor', '4.2.4'
#gem 'ckeditor', '5.1.3'
#gem 'carrierwave'
#gem 'mini_magick'
gem 'cancancan'
gem 'paperclip'
gem 'sanitize'
#gem 'formtastic', '~> 1.2.4'
gem 'formtastic'
#gem "will_paginate", "~> 3.0.pre2"
gem "will_paginate", "~> 3.1.7"
gem "nifty-generators"
gem "nokogiri"
gem "liquid"
#gem 'imagesize', :require => 'image_size'
gem 'image_size'
gem 'twitter'
gem "json"
gem 'link_thumbnailer'
#gem 'ruby-oembed', :require => 'oembed'
#gem 'ruby-oembed'
#gem 'embedly'
# tmail conflicts with formtastic. Should be required only where used. app/mailers/receive_mailer
#gem 'tmail', :require => false
#gem 'exception_notification', :require => 'exception_notifier'
gem 'exception_notification'

gem 'postmark'
gem 'postmark-rails'

gem 'responds_to_parent'

gem 'deep_cloneable'

gem 'down'

gem "passenger", ">= 6.0.16", require: "phusion_passenger/rack_handler"

gem "mimemagic", ">=0.3.10"

gem 'sitemap_generator'

# assets:precompile seems to be missing this
gem "date"

group :development, :test do
  gem 'capistrano'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails'
  gem 'web-console'  
  gem 'rspec-rails'
  #gem 'capybara'
  #gem 'selenium-webdriver'
  #gem 'capybara-webkit'
  #gem 'factory_girl_rails'
  gem 'factory_bot_rails'
  gem 'thin'
end

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  #gem 'therubyracer', :platforms => :ruby
  gem 'mini_racer', '~> 0.4.0'

  gem 'uglifier'

  gem 'sprockets', '~> 3.7.2'
  
  #gem 'libv8'
#end

gem 'ed25519', '~> 1.3'
gem 'bcrypt_pbkdf', '~> 1.1'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
