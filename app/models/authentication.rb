class Authentication < ActiveRecord::Base
  belongs_to :participant, optional: true
  
  def provider_name
    if provider == 'open_id'
      "OpenID"
    else
      provider.titleize
    end
  end
  
end
