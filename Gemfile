source 'http://rubygems.org'

ruby '3.2.11'

#gem 'rails', '~> 3.2'
#gem 'rails', '~> 4.2'
gem 'rails', '~> 8.0.0'
gem 'rake'

gem 'activerecord-session_store'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'rack-cors', :require => 'rack/cors'

gem "openssl", '3.1.0'  # Ruby 3.2 default-gem pin (Passenger preload; see block below)

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


gem 'rmagick', :require => "rmagick"
gem 'acts-as-taggable-on'
#gem 'simple_captcha'
#gem 'ckeditor', '3.4.2.pre'
#gem 'ckeditor', '5.1.3'
#gem 'carrierwave'
#gem 'mini_magick'
gem 'cancancan'
# kt-paperclip is the maintained fork of paperclip; paperclip 3.2.1 (the version
# the old unversioned line resolved to) is incompatible with Rails 5.2 — its
# post_process callback calls run_callbacks with the pre-5.0 arity and crashes
# every image upload. kt-paperclip keeps the same `Paperclip` API.
# 7.x is Rails-7/8-aware (fixed the AttachmentSizeValidator::CHECKS constant Rails 7
# removed) so the paperclip_rails7_size_validator shim is no longer needed. 7.0
# swapped mimemagic -> marcel for content-type detection (image/* validations
# unaffected). Staying on 7.x (8.0 is brand-new + adds deprecations).
gem 'kt-paperclip', '~> 7.3', require: 'paperclip'
gem 'sanitize'
#gem 'formtastic', '~> 1.2.4'
gem 'formtastic'
#gem "will_paginate", "~> 3.0.pre2"
gem "will_paginate", "~> 4.0"  # 4.0 adds Rails 7 support (3.x helper breaks under Rails 7.1)
gem "nokogiri", '1.15.7'  # pin: production Ubuntu 18.04 (glibc 2.27); nokogiri 1.16+ linux gems need glibc 2.28
gem "liquid"
# The ActivityPub code (app/lib/activity_pub.rb, activitypub_controller) uses the
# `http` gem (HTTP.timeout / HTTP.get). It used to come transitively via the now-
# removed `twitter` gem, so declare it directly. Pin to 4.x (what it was written
# against; 5.x needs Ruby 3.0).
gem 'http', '~> 4.4'
#gem 'imagesize', :require => 'image_size'
gem 'image_size'
gem "json", '2.6.3'  # Ruby 3.2 default-gem pin (Passenger preload; see block below)
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


gem 'deep_cloneable'

gem 'down'

gem "passenger", ">= 6.0.16", require: "phusion_passenger/rack_handler"

gem 'sitemap_generator'

# assets:precompile seems to be missing this
gem "date", '3.3.3'  # Ruby 3.2 default-gem pin (see block below)

gem 'rexml', '~> 3.2'

# Ruby 3.2 default-gem pins. These ship WITH Ruby 3.2.11 as default gems, and
# Passenger's rack-preloader activates the Ruby-shipped versions before Bundler
# runs. If the lock pins newer versions, boot dies with
# "already activated <gem> X, but your Gemfile requires Y (Gem::LoadError)".
# Pin each to the exact version Ruby 3.2.11 ships so there is no conflict.
# (bigdecimal 4.x additionally requires Ruby >= 3.4.) Revisit on the next Ruby bump.
gem 'base64', '0.1.1'
gem 'bigdecimal', '3.1.3'
gem 'observer', '0.1.1'
gem 'racc', '1.6.2'
gem 'logger', '1.5.3'
gem 'net-protocol', '0.2.1'
gem 'ostruct', '0.5.5'
# NOTE timeout + securerandom are NOT pinned to the Ruby 3.2 default: Rails 7.1
# requires timeout >= 0.4.0 and securerandom >= 0.3, newer than Ruby 3.2.11
# ships. They are therefore ahead of the system default — if the Passenger
# rack-preloader pre-activates either before Bundler, boot would Gem::LoadError
# (as base64 did on the Ruby-3 bump). Verify on staging; if it bites, install
# the newer versions into the server rbenv Ruby (gem install timeout -v ...).
# Added with the Rails 7 bump (Rails 7 pulls these as explicit deps):
gem 'drb', '2.1.1'
gem 'mutex_m', '0.1.2'
gem 'cgi', '0.3.7'
# json + openssl pinned at their existing declarations above (lines ~17, ~81)

group :development, :test do
  gem 'capistrano'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails'
  gem 'ed25519', '~> 1.3'
  gem 'bcrypt_pbkdf', '>= 1.1', '< 2.0'
  gem 'rspec-rails'
  #gem 'capybara'
  #gem 'selenium-webdriver'
  #gem 'capybara-webkit'
  #gem 'factory_girl_rails'
  gem 'factory_bot_rails'
  gem 'thin'
end

group :development do
  # web-console must NOT load in test: it calls exit during boot there.
  gem 'web-console'
end

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  #gem 'therubyracer', :platforms => :ruby
  gem 'mini_racer', '~> 0.6.4'

  gem 'uglifier'
  # Rails 7 pulls actiontext/activestorage, whose engines register ES6 JS for
  # precompilation; Uglifier (ES5-only) chokes on `const`. terser is the modern
  # ES6-aware minifier (drop-in replacement) — see js_compressor in production.rb.
  gem 'terser'

  gem 'sprockets', '~> 3.7.2'
  
  #gem 'libv8'
#end

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
