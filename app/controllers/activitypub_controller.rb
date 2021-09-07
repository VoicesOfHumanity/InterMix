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
          "url" => "https://#{BASEDOMAIN}#{@icon_url}"
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
    
    #record_response(results_json)
    
    expires_in 3.days, public: true
    #render json: results_json, content_type: 'application/jrd+json'
    render json: results_json, content_type: 'application/activity+json'
  end
  
  def community_info
    # account info for a community
  end
  
  def conversation_info
    # account info for a conversation
  end
  
  def voh_info
    # account info for order out of chaos
  end
  
  def inbox
    # Where items for a certain user arrive
    # Somebody is sending us something
    render json: {"message" => "Thank you!"}, content_type: 'application/activity+json'    
  end
  
  def feed
    # The outbox. A user's public posts.
    # Should really be divided into pages. For now it is everything
    post_list = []

    @account_url = @account.account_url
    
    items = Item.where(posted_by: @account.id, censored: false, intra_com: 'public', intra_conv: 'public', wall_delivery: 'public').order("id desc")
    for item in items
      unique_post_id = "https://#{BASEDOMAIN}/p_#{item.posted_by}_#{item.id}"
      from_participant = item.participant
      
      to = "https://www.w3.org/ns/activitystreams#Public"
      cc = [
        "#{@account_url}/followers.json"
      ]

      published = item.created_at.strftime("%Y-%m-%dT%H:%M:%S.%L%z")
      
      replying_to = nil
      if item.reply_to.to_i > 0
        previous = Item.find_by_id(item.reply_to)
        if previous
          if previous.posted_by_remote_actor_id.to_i > 0
            replying_to = previous.remote_reference            
          else
            replying_to = "https://#{BASEDOMAIN}/p_#{previous.posted_by}_#{previous.id}"
          end
        end
      end

      subject = item.subject
      content = item.html_content
      fullcontent = "<p><strong>** #{subject} **</strong></p>\n" + content
      
      post = {
        "id": unique_post_id,
        "type": "Create",
        "actor": from_participant.activitypub_url,
        "object": {
        	"id": unique_post_id,
    	    "type": "Note",
    	    "published": published,
    	    "attributedTo": from_participant.activitypub_url,
    	    "content": fullcontent,
    	    "to": to,
          "cc": cc,
          "inReplyTo": replying_to
        }  
      }
      
      post_list << post
    end
    
    url = "#{@account_url}/feed.json"   # https://intermix.cr8.com/u/ff2580/feed.json
    
    results = {
      	"@context" => "https://www.w3.org/ns/activitystreams",
        "id" => url,
        "type" => "OrderedCollectionPage",
        "totalItems" => post_list.length,
        "orderedItems" => post_list
    }

    results_json = results.to_json
        
    render json: results_json, content_type: 'application/activity+json'         
        
  end
  
  def following
    # Who this user is following
    follows_list = []
    follows = Follow.where(following_id: @account.id)
    for f in follows
      if f.followed_id.to_i > 0 and f.idol
        # An internal user
        followed_url = "https://#{BASEDOMAIN}/u/#{f.idol.account_uniq}"
      elsif f.followed_remote_actor_id.to_i > 0 and f.remote_idol
        followed_url = f.remote_idol.account_url
      else
        next
      end        
      follows_list << followed_url
    end   

    @account_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}"
    url = "#{@account_url}/following.json"   # https://intermix.cr8.com/u/ff2580/following.json
    
    results = {
      	"@context" => "https://www.w3.org/ns/activitystreams",
        "id" => url,
        "type" => "OrderedCollectionPage",
        "totalItems" => follows_list.length,
        "orderedItems" => follows_list
    }
    
    results_json = results.to_json
        
    render json: results_json, content_type: 'application/activity+json'         
  end
  
  def followers
    # Who follows this user
    follower_list = []
    followers = Follow.where(followed_id: @account.id)
    for f in followers
      if f.following_id.to_i > 0 and f.follower
        # An internal user
        following_url = "https://#{BASEDOMAIN}/u/#{f.follower.account_uniq}"
      elsif f.following_remote_actor_id.to_i > 0 and f.remote_follower
        # a remote user 
        following_url = f.remote_follower.account_url
      else
        next
      end        
      follower_list << following_url            
    end
    
    @account_url = "https://#{BASEDOMAIN}/u/#{@account.account_uniq}"
    url = "#{@account_url}/followers.json"   # https://intermix.cr8.com/u/ff2580/followers.json

    results = {
      	"@context" => "https://www.w3.org/ns/activitystreams",
        "id" => url,
        "type" => "OrderedCollectionPage",
        "totalItems" => follower_list.length,
        "orderedItems" => follower_list
    }
    
    results_json = results.to_json
        
    render json: results_json, content_type: 'application/activity+json'    
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
	  #"@context": "https://www.w3.org/ns/activitystreams",
	  #"id": "https://my-example.com/my-first-follow",
	  #"type": "Follow",
	  #"actor": "https://my-example.com/actor",
	  #"object": "https://mastodon.social/users/Mastodon"
    #}
    
    from_id = current_participant.id
    
    if not params.has_key?(:fedfollow) or params[:fedfollow].to_s == ''
      flash[:alert] = "Didn't get anything to follow"
      redirect_to = 'me/friends'
      return
    end
    
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
    
    logger.info("activitypub#follow_account add follower record")
    follow = Follow.where(following_id: current_participant.id, followed_fulluniq: to_actor).first
    if not follow
      follow = Follow.create(
        following_id: current_participant.id,
        followed_fulluniq: to_actor,
        int_ext: 'ext'
      )
    end
    
    unique_follow_id = "https://#{BASEDOMAIN}/f_#{current_participant.id}_#{follow.id}"
    
    follow.remote_reference = unique_follow_id
    follow.followed_remote_actor_id = remote_actor.id
    follow.save    
    
    object = {
      "@context": [
            "https://www.w3.org/ns/activitystreams",
            "https://w3id.org/security/v1"
          ],
      "type": "Follow",
      "id": unique_follow_id,
      "actor": current_participant.activitypub_url,
      "object": remote_actor.account_url
    }
    
    req = sign_and_send(current_participant.id, remote_actor, object, 'follow_account')
        
    follow.api_request_id = req.id
    follow.save    
    
    flash[:notice] = "Follow request sent"
    respond_to do |format|
     format.html {redirect_to '/me/friends'}
    end

  end
  

end


