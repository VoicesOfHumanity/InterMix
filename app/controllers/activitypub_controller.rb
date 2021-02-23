require 'openssl'

class ActivitypubController < ApplicationController

  before_action :record_request
  before_action :get_account 

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
    
    # Possible more things to include, from Mastodon:
    #"discoverable" => true,
    #"suspended" => false,
    
    results_json = results.to_json
    
    record_response(results_json)
    
    expires_in 3.days, public: true
    render json: results_json, content_type: 'application/jrd+json'
  end
  
  def inbox
    # Where items for a certain user arrive
  end
  
  def feed
    # The outbox. A user's public posts.
    
  end
  
  def following
    # Who this user is following
    follows_list = []
    follows = Follow.where(following_id: @account.id)
    for f in follows
      if f.followed_id.to_i > 0 and f.idol
        # An internal user
        followed_fulluniq = f.idol.account_uniq_full
      elsif f.followed_fulluniq.to_s != ''
        followed_fulluniq = f.followed_fulluniq
      else
        continue
      end        
      follows_list << followed_fulluniq
    end    
  end
  
  def followers
    # Who follows this user
    follower_list = []
    followers = Follow.where(followed_id: @account.id)
    for f in followers
      if f.following_id.to_i > 0 and f.follower
        # An internal user
        following_fulluniq = f.follower.account_uniq_full
      elsif f.followed_fulluniq.to_s != ''
        following_fulluniq = f.followed_fulluniq
      else
        continue
      end        
      follower_list << following_fulluniq            
    end
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

    @account_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}"
    
    results = {
      "@context" => "https://w3id.org/security/v1",
      "@id" => "#{@account_url}/key.json",
      "@type" => "Key",
      "@owner" => @account_url,
      "publicKeyPem" => @account.public_key
    }
    
    results_json = results.to_json
    
    record_response(results_json)

    expires_in 3.days, public: true
    render json: results_json, content_type: 'application/jrd+json'
  end
  
  def unknown_target
    # Anything we don't seem to know what to do with
    logger.info("activitypub#record_request unknown target")
    render plain: "I don't know what to do with that", status: :bad_request
    return
  end
  
  private
  
  def get_account
    @account_uniq = params[:acct_id]
    @account = Participant.find_by_account_uniq(@account_uniq)
    if not @account
      render plain: "Unknown account #{account_uniq}", status: :not_found
      return
    elsif @account.status != 'active'
      render plain: "The account #{account_uniq} is not active", status: :forbidden
      return
    end
    @account_id = @account.id
    @participant_id = @account_id
  end
  
  def record_request
    # Record what we're receiving. Later, we can add our response
    begin
      @api_request = ApiRequest.create(
        request_headers: request.env.select {|k,v| k =~ /^HTTP_/ and ! k.starts_with?("HTTP_COOKIE")}.to_json,
        request_content_type: request.format,
        request_method: request.method,
        remote_ip: request.remote_ip,
        path: request.fullpath,
        user_agent: request.headers.key?('User-Agent') ? request.headers['User-Agent'] : '',
        request_body: request.body.read,
        account_uniq: params.key?(:acct_id) ? params[:acct_id] : '',
        our_function: action_name
      )
    rescue Exception => e
      logger.info("activitypub#record_request error: #{e}")
    end
  end
  
  def record_response(results_json)
    # update the record with the results, if any
    @api_request.response_body = results_json
    @api_request.participant_id = @account.id if @account
    @api_request.processed = true
    @api_request.save
  end
  
  def deliver_post(from_id, to_actor)
    # Send a post to somebody's inbox. Probably sign_and_send instead of this
    # We'd first need to figure out their inbox
    

    document      = File.read('create-hello-world.json')
    date          = Time.now.utc.httpdate
    keypair       = OpenSSL::PKey::RSA.new(File.read('private.pem'))
    signed_string = "(request-target): post /inbox\nhost: mastodon.social\ndate: #{date}"
    signature     = Base64.strict_encode64(keypair.sign(OpenSSL::Digest::SHA256.new, signed_string))
    header        = 'keyId="https://my-example.com/actor",headers="(request-target) host date",signature="' + signature + '"'

    HTTP.headers({ 'Host': 'mastodon.social', 'Date': date, 'Signature': header })
        .post('https://mastodon.social/inbox', body: document)
    
  end
  
  def follow_account
    # Follow somebody
    #POST /@alice/outbox HTTP/1.1
    #Host: social.example.com
    #Content-Type: application/activity+json
    #{
    #  "type": "Follow",
    #  "object": "https://social.example.com/@bob"
    #}
    
  end
  
  def sign_and_send(from_id, to_actor, object)
    # Send something to a remote user's inbox
    
  end

end


