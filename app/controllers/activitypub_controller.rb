require 'openssl'

class ActivitypubController < ApplicationController

  def account_info
    # Show info for a user, after accessing something like: https://intermix.test:3002/u/ff1888
    # This is an ActivePub Actor object
    # Should look something like:
    #{
    #	"@context": [
    #		"https://www.w3.org/ns/activitystreams",
    #		"https://w3id.org/security/v1"
    #	],
    #	"id": "https://my-example.com/actor",
    #	"type": "Person",
    #	"preferredUsername": "alice",
    #	"inbox": "https://my-example.com/inbox",
    #	"publicKey": {
    #		"id": "https://my-example.com/actor#main-key",
    #		"owner": "https://my-example.com/actor",
    #		"publicKeyPem": "-----BEGIN PUBLIC KEY-----...-----END PUBLIC KEY-----"
    #	}
    #}
    # or
    # {
    # "@context": ["https://www.w3.org/ns/activitystreams",
    #           {"@language": "ja"}],
    # "type": "Person",
    # "id": "https://kenzoishii.example.com/",
    # "following": "https://kenzoishii.example.com/following.json",
    # "followers": "https://kenzoishii.example.com/followers.json",
    # "liked": "https://kenzoishii.example.com/liked.json",
    # "inbox": "https://kenzoishii.example.com/inbox.json",
    # "outbox": "https://kenzoishii.example.com/feed.json",
    # "preferredUsername": "kenzoishii",
    # "name": "石井健蔵",
    # "summary": "この方はただの例です",
    # "icon": [
    #   "https://kenzoishii.example.com/image/165987aklre4"
    # ]
    # }
    # Good compatibility hints:
    # https://flak.tedunangst.com/post/the-activity-person-examined

    
    account_uniq = params[:acct_id]

    @account = Participant.find_by_account_uniq(account_uniq)

    @account_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}"
    
    @inbox_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}/inbox"
    @outbox_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}/feed.json"
    
    @following_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}/following.json"
    @followers_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}/followers.json"

    @liked_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}/liked.json"
    
    @icon_url = ""
    if @account.picture.exists?
      @icon_url = @account.picture.url(:medium)
    end
        
    results = {
      	"@context" => [
      		"https://www.w3.org/ns/activitystreams",
      		"https://w3id.org/security/v1",
          {"@language": "en"}
      	],
        "type" => "Person",
        "id" => @account_url,
        "url" => @account_url,
        "preferredUsername" => @account.account_uniq,
        "name" => @account.account_uniq,
        "summary" => "VoH user",
        "inbox" => @inbox_url,
        "outbox" => @outbox_url,
        "following" => @following_url,
        "followers" => @followers_url,
        "liked" => @liked_url,
        "icon" => {
          "mediaType" => "image/jpeg",
          "type" => "icon",
          "url" => @icon_url
        },
        "publicKey" => {
          "id" => "#{@account_url}#key",
          "owner" => @account_url,
          "publicKeyPem" => @account.public_key
        } 
    }
    
    results_json = results.to_json
    
    expires_in 3.days, public: true
    render json: results_json, content_type: 'application/jrd+json'
  end
  
  def inbox
    # Where items for a certain user arrive
  end
  
  def feed
    # The outbox. A users posts.
    
  end
  
  def account_key
    # Return the key information for an account, in this format:
    # https://web-payments.org/vocabs/security#publicKey
    #{
    #  "@context": "https://w3id.org/security/v1",
    #  "@id": "https://payswarm.example.com/i/bob/keys/1",
    #  "@type": "Key",
    #  "owner": "https://payswarm.example.com/i/bob",
    #  "publicKeyPem": "-----BEGIN PRIVATE KEY-----\nMIIBG0BA...OClDQAB\n-----END PRIVATE KEY-----\n"
    #}
    # Seems that it is a problem when it is in a separate URL, so not sure if this will be used

    account_uniq = params[:acct_id]
    @account = Participant.find_by_account_uniq(account_uniq)
    @account_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}"
    
    results = {
      "@context" => "https://w3id.org/security/v1",
      "@id" => "#{@account_url}/key.json",
      "@type" => "Key",
      "@owner" => @account_url,
      "publicKeyPem" => @account.public_key
    }
    
    results_json = results.to_json
    
    expires_in 3.days, public: true
    render json: results_json, content_type: 'application/jrd+json'
  end  


end


