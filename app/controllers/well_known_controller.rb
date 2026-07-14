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
    # /.well-known/host-meta — XRD document advertising the webfinger endpoint.
    # Some servers fetch this to discover the webfinger template before querying.
    xml = <<~XRD
      <?xml version="1.0" encoding="UTF-8"?>
      <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
        <Link rel="lrdd" type="application/jrd+json" template="https://#{BASEDOMAIN}/.well-known/webfinger?resource={uri}"/>
      </XRD>
    XRD
    expires_in 3.days, public: true
    render xml: xml, content_type: 'application/xrd+xml'
  end

  def nodeinfo
    # /.well-known/nodeinfo — discovery document pointing at the NodeInfo 2.0 schema.
    results = {
      'links' => [
        {
          'rel' => 'http://nodeinfo.diaspora.software/ns/schema/2.0',
          'href' => "https://#{BASEDOMAIN}/nodeinfo/2.0"
        }
      ]
    }
    expires_in 1.day, public: true
    render json: results.to_json, content_type: 'application/json'
  end

  def nodeinfo_schema
    # /nodeinfo/2.0 — the actual NodeInfo 2.0 document with instance metadata.
    total_users = (Participant.where(status: 'active').count rescue 0)
    local_posts = (Item.where(int_ext: 'int').count rescue 0)
    results = {
      'version' => '2.0',
      'software' => { 'name' => 'intermix', 'version' => '1.0' },
      'protocols' => ['activitypub'],
      'services' => { 'inbound' => [], 'outbound' => [] },
      'openRegistrations' => true,
      'usage' => {
        'users' => { 'total' => total_users },
        'localPosts' => local_posts
      },
      'metadata' => { 'nodeName' => 'InterMix' }
    }
    expires_in 1.day, public: true
    render json: results.to_json, content_type: 'application/json; profile="http://nodeinfo.diaspora.software/ns/schema/2.0#"'
  end

end
