# https://tools.ietf.org/html/rfc7033
# /.well-known/webfinger?resource=acct:bob@my-example.com
# /.well-known/webfinger?resource=acct:ff6@voh.intermix.com
# https://intermix.test:3002/.well-known/webfinger?resource=acct:ff1888@intermix.test

class WellKnownController < ApplicationController

  before_action { response.headers['Vary'] = 'Accept' }

  def webfinger
    # We get here from a URL like this:
    # /.well-known/webfinger?resource=acct:ff6@voh.intermix.com

    if not params.has_key? :resource
      render plain: "We would expect something like /.well-known/webfinger?resource=acct:username@#{BASEDOMAIN}", status: :bad_request
      return
    end
    
    resource = params[:resource].strip.downcase
    
    # To start with, we're expecting only webfinger requests for an account, not posts, etc
    # But we should really recognize http, https, mailto, and others
    resource.gsub!(/\Aacct:/, '')
    
    xarr = resource.split('@')
    if xarr.length != 2
      render plain: "That's not the right format for an account identifier", status: :not_found
      return
    end
    username = xarr[0]
    domain = xarr[1]
    if username.strip == '' or domain.strip == ''
      render plain: "For an account identifier we need both a username and a domain name", status: :not_found
      return
    end
    
    # We would expect the domain to be BASEDOMAIN. ROOTDOMAIN would be ok too.
    if domain != BASEDOMAIN and domain != ROOTDOMAIN
      render plain: "We don't seem to recognize domain #{domain}", status: :not_found
      return
    end

    @account = Participant.find_by_account_uniq_full(resource)
    if not @account
      render plain: "Unknown account #{resource}", status: :not_found
      return
    elsif @account.status != 'active'
      render plain: "The account #{resource} is not active", status: :forbidden
      return
    end
    
    @account_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}"
    
    results = {
      'subject' => "acct:#{@account.account_uniq_full}",
      'links' => [
        {
          'rel' => 'self',
          'type' => 'application/activity+json',
          'href' => @account_url
        }
      ]
    }
    
    results_json = results.to_json
    
    #{
    #	"subject": "acct:alice@my-example.com",
    #	"links": [
    #		{
    #			"rel": "self",
    #			"type": "application/activity+json",
    #			"href": "https://my-example.com/actor"
    #		}
    #	]
    #}
    
    expires_in 3.days, public: true
    render json: results_json, content_type: 'application/jrd+json'
  end
  
  def hostmeta
  end
  
  def nodeinfo
  end

end
