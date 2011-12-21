require 'openid/store/filesystem'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, "151526481561013", "3653366f2b6d4778e09db3d666d1fedf"
  provider :twitter, 'h7fBR0BHj4ZsGiDiB0AiA', 'mIBk37eomiVGcSUyF8d3pYhlDwIHMvPQMeuRZdgKJE'
  #provider :open_id, OpenID::Store::Filesystem.new('/tmp')
  #provider :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
end