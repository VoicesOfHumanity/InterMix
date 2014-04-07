#require 'openid/store/filesystem'
#
#Rails.application.config.middleware.use OmniAuth::Builder do
#  if Rails.env.development?
#    provider :facebook, "1406266652976637", "ec6fc05777932b40f23434bdbdadabec"
#  else  
#    provider :facebook, "151526481561013", "3653366f2b6d4778e09db3d666d1fedf"
#  end
#  provider :twitter, 'h7fBR0BHj4ZsGiDiB0AiA', 'mIBk37eomiVGcSUyF8d3pYhlDwIHMvPQMeuRZdgKJE'
#  #provider :open_id, OpenID::Store::Filesystem.new('/tmp')
#  #provider :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
#end