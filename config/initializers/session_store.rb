# Be sure to restart your server when you modify this file.

#Intermix::Application.config.session_store :cookie_store, :key => '_intermix_session', :domain => ".#{ROOTDOMAIN}"

Rails.application.config.session_store :cookie_store, key: '_intermix_session', domain: ".#{ROOTDOMAIN}", same_site: :lax

