class RemoteActor < ApplicationRecord
  serialize :json_got
  
  def thumb_or_blank
    # Return a link to a 50x50 thumbnail picture    
    if self.icon_url and self.icon_url.to_s != ''
      return self.icon_url  
    else
      return "https://#{BASEDOMAIN}/images/default_user_icon-50x50.png"
    end
  end
  
end
