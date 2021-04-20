require 'openssl'
require 'http'

class ActivitypubController < ApplicationController

  before_action :record_request, except: [:follow_account]
  before_action :get_account, except: [:follow_account]
  before_action :authenticate_participant!, only: [:follow_account]

  include ActivityPub
  
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
    #render json: results_json, content_type: 'application/jrd+json'
    render json: results_json, content_type: 'application/activity+json'
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

  def follow_account
    # Follow somebody remote. Might be called from friend list
    #POST /@alice/outbox HTTP/1.1
    #Host: social.example.com
    #Content-Type: application/activity+json
    #{
    #  "type": "Follow",
    #  "object": "https://social.example.com/@bob"
    #}
    
    from_id = current_participant.id
    
    # Should probably accept either an email like identifier ming@social.coop or the url https://social.coop/users/ming
    # but for now, only the one that looks like an email
    to_actor = normalize_actor(params[:fedfollow])
    
    if to_actor == ""
      flash[:alert] = "You didn't enter anything that looked like a Fediverse ID/address"
      redirect_to = 'me/friends'
      return
    #elsif not to_actor =~ URI::MailTo::EMAIL_REGEXP
    #  flash[:alert] = "That doesn't look like a valid address"
    #  redirect_to = 'me/friends'
    #  return 
    end
    
    # something like https://social.coop/users/ming
    #if to_actor[0..4] == 'http'
    #  actor_url = to_actor
    #elsif not to_actor =~ URI::MailTo::EMAIL_REGEXP
    #  flash[:alert] = "That doesn't look like a valid address"
    #  redirect_to = 'me/friends'
    #  return 
    #else
    #  actor_url = get_actor_url_by_webfinger(to_actor)
    #end
    #flash[:notice] = "Remote url: #{actor_url}"
    #logger.info "activitypub#follow_account remote url: #{actor_url}"

    if not to_actor =~ URI::MailTo::EMAIL_REGEXP
      flash[:alert] = "That doesn't look like a valid address"
      respond_to do |format|
       format.html {redirect_to '/me/friends'}
      end
      return
    end
    
    remote_actor = get_remote_actor(to_actor)
    if not remote_actor
      flash[:alert] = "We didn't succeed in looking up that address"
      respond_to do |format|
       format.html {redirect_to '/me/friends'}
      end
      return
    end
    
    object = {
      "@context": [
            "https://www.w3.org/ns/activitystreams",
            "https://w3id.org/security/v1"
          ],
      "type": "Follow",
      "object": remote_actor.account_url
    }
    
    sign_and_send(current_participant.id, remote_actor, object, 'follow_account')
    
    logger.info("activitypub#follow_account add follower record")
    follow = Follow.where(following_id: current_participant.id, followed_fulluniq: to_actor).first
    if not follow
      follow = Follow.create(
        following_id: current_participant.id,
        followed_fulluniq: to_actor,
        int_ext: 'ext'
      )
    end
    follow.followed_remote_actor_id = remote_actor.id
    follow.save
    
    flash[:notice] = "Follow request sent"
    respond_to do |format|
     format.html {redirect_to '/me/friends'}
    end

  end
  

end


