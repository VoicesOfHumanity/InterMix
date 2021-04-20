module ActivityPub
  
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
    logger = @logger if @logger and not logger
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
    
  def sign_and_send(from_id, to_remote_actor, object, our_function)
    # Send something to a remote user's inbox
    # inspired by https://glitch.com/edit/#!/glib-cheerful-addition?path=routes%2Finbox.js%3A1%3A0
    # and https://blog.joinmastodon.org/2018/06/how-to-implement-a-basic-activitypub-server/
    # We're signing the message with the private key of the sender
    
    logger = @logger if @logger and not logger
    
    inbox_url = to_remote_actor.inbox_url
    if not inbox_url or not inbox_url =~ /^http/
      logger.info "activitypub#sign_and_send No inbox URL for #{to_remote_actor.account}"
      return false
    end
    logger.info "activitypub#sign_and_send inbox url: #{inbox_url}"
    
    if not current_participant or from_id != current_participant.id
      from_user = Participant.find_by_id(from_id)
    else
      from_user = current_participant
    end
    
    private_key = OpenSSL::PKey::RSA.new(from_user.private_key)
    
    uri = URI(inbox_url)
    inbox_host = uri.host
    inbox_path = uri.path
    
    key_id = "https://#{BASEDOMAIN}/u/#{from_user.account_uniq}#key"
       
    date          = Time.now.utc.httpdate
    digest        = Base64.strict_encode64((OpenSSL::Digest::SHA256.new).digest(object.to_json))
    signed_string = "(request-target): post #{inbox_path}\nhost: #{inbox_host}\ndate: #{date}\ndigest: SHA-256=#{digest}"
    signature     = Base64.strict_encode64(private_key.sign(OpenSSL::Digest::SHA256.new, signed_string))
    sig_header    = 'keyId="' + key_id + '",headers="(request-target) host date digest",signature="' + signature + '"'

    headers = { 'Host': inbox_host, 'Date': date, 'Signature': sig_header, 'digest': "SHA-256="+digest }

    @api_send = ApiSend.create(
      participant_id: from_user.id,
      remote_actor_id: to_remote_actor.id,
      to_url: inbox_url,
      request_method: 'post',
      request_headers: headers,
      request_object: object,
      our_function: our_function
    )

    res = HTTP.headers(headers).post(inbox_url, body: object.to_json)
    
    @api_send.response_code = res.code
    @api_send.response_body = res.body
    @api_send.save
    
    return true
  end

  def normalize_actor(actor_uniq)
    # clean up an actor id a little bit
    actor_uniq.strip.downcase!
    actor_uniq[0] = '' if actor_uniq[0] == '@'
    actor_uniq
  end
  
  def get_remote_actor(actor_uniq)
    # Get information about a remote account, either by asking, or from our cache
    logger = @logger if @logger and not logger
    remote_actor = RemoteActor.find_by_account(actor_uniq)
    if remote_actor and remote_actor.last_fetch >= Date.today - 7
      get_new = false
      logger.info("activitypub#get_remote_actor already have recent info for #{actor_uniq}")
    else
      get_new = true
      if remote_actor
        logger.info("activitypub#get_remote_actor we have info for #{actor_uniq}, but not recent enough")
      else
        logger.info("activitypub#get_remote_actor we have no info for #{actor_uniq}")
      end
    end    
    if get_new
      actor_url = get_actor_url_by_webfinger(actor_uniq)
      if actor_url.to_s != ''

        logger.info("activitypub#get_remote_actor getting #{actor_url}")

        try_again = true
        redirect_count = 0
        while try_again and redirect_count <= 3      
          uri = URI.parse(actor_url)
        
          req = Net::HTTP::Get.new(uri.path)
          req['Accept'] = "application/json"
          req['User-Agent'] = "InterMix VoH"

          response = nil
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            http.request(req)
          end

          if response
            logger.info("activitypub#get_remote_actor response: #{response.code}")
          else
            logger.info("activitypub#get_remote_actor no reponse")
            return nil
          end
          
          # Mastodon redirects https://social.coop/users/ming to https://social.coop/@ming
          
          if response.code.to_i == 301 or response.code.to_i == 302
            actor_url = response['location']
            logger.info("activitypub#get_remote_actor redirecting to #{actor_url}")
            redirect_count += 1
            if redirect_count >= 3
              try_again = false
              break
            end
          else
            try_again = false
            break
          end        
        end
        
        if not response
          logger.info("activitypub#get_remote_actor no reponse")
          return nil          
        elsif response.code.to_i == 301 or response.code.to_i == 302
          logger.info("activitypub#get_remote_actor too many redirections")
          return nil
        end
        
        if response.code.to_i == 200
          body = response.body
          #logger.info("activitypub#get_remote_actor body: #{body}")     
          begin
            data = JSON.parse(body)
          rescue
            logger.info("activitypub#get_remote_actor couldn't read any json data}")
            return nil
          end
          if data and data.has_key? 'inbox'
            if not remote_actor
              remote_actor = RemoteActor.create(
                account: actor_uniq
              )
            end
            remote_actor.account_url = actor_url
            remote_actor.json_got = data
            remote_actor.username = data['preferredUsername'] if data.has_key?('preferredUsername')
            remote_actor.name = data['name'] if data.has_key?('name')
            remote_actor.summary = data['summary'] if data.has_key?('summary')
            remote_actor.inbox_url = data['inbox'] if data.has_key?('inbox')
            remote_actor.outbox_url = data['outbox'] if data.has_key?('outbox')
            if data.has_key?('publicKey') and data['publicKey'].class == Hash and data['publicKey'].has_key?('publicKeyPem')              
              remote_actor.public_key = data['publicKey']['publicKeyPem']
            end
            if data.has_key?('icon') and data['icon'].class == Hash and data['icon'].has_key?('url')
              remote_actor.icon_url = data['icon']['url']
            end
            if data.has_key?('image') and data['image'].class == Hash and data['image'].has_key?('url')
              remote_actor.image_url = data['image']['url']
            end
            remote_actor.last_fetch = Time.now
            remote_actor.save   
          else
            logger.info("activitypub#get_remote_actor unexpected json data}")
            return nil
          end
        else
          logger.info("activitypub#get_remote_actor got response code #{response.code} to #{actor_url}")
          #logger.info("activitypub#get_remote_actor body:#{response.body}")
          return nil
        end
      end
    end
    return remote_actor
  end
  
  def get_actor_url_by_webfinger(actor_addr)
    # Get an address like ming@social.coop and return a url id like https://social.coop/users/ming
    # We need to do a webfinger lookup to the remote server to get that
    logger = @logger if @logger and not logger
    
    actor_url = ''
    
    xarr = actor_addr.split("@")
    if xarr.length != 2
      return ''
    end
    domain = xarr[1]
    
    wurl = "https://#{domain}/.well-known/webfinger?resource=acct:#{actor_addr}"
    response = HTTP.get(wurl)
    
    if response.code.to_i == 200
      body = response.body
      logger.info("activitypub#get_actor_url_by_webfinger body: #{body}")
      # From Mastodon:
      # {"subject":"acct:ming@social.coop","aliases":["https://social.coop/@ming","https://social.coop/users/ming"],"links":[{"rel":"http://webfinger.net/rel/profile-page","type":"text/html","href":"https://social.coop/@ming"},{"rel":"self","type":"application/activity+json","href":"https://social.coop/users/ming"},{"rel":"http://ostatus.org/schema/1.0/subscribe","template":"https://social.coop/authorize_interaction?uri={uri}"}]}
      begin
        data = JSON.parse(body)
      rescue
        logger.info("activitypub#get_actor_url_by_webfinger couldn't read any json data}")
      end
      if data and data.has_key? 'links' and data['links'].class == Array
        links = data['links']
        links.each do |link|
          if link.has_key?('rel') and link['rel']=='self' and link.has_key?('href')
            actor_url = link['href']
            break
          end
        end
      else
        logger.info("activitypub#get_actor_url_by_webfinger unexpected json data}")
      end
    else
      logger.info("activitypub#get_actor_url_by_webfinger got response code #{response.code} to #{wurl}")
      return ''
    end
  
    return actor_url
  end
  
  def get_actor_inbox_from_url(actor_url)
    # Look up the inbox address, based on the actor's ID url

    actor_inbox = ''

    response = HTTP.get(actor_url)
    
    if response.code.to_i == 200
    
    else
      
    end
    
    return actor_inbox
  end

  def respond_to_follow
    #-- Answer a follow request from the outside. We'll probably want to do that automatically right away
    
    participant_id = 2602                         # current_participant.id
    to_actor = "ming@social.coop"                 # ming@social.coop
    remote_actor = get_remote_actor(to_actor)      
    remote_actor_url = remote_actor.account_url   # https://intermix.cr8.com/u/ff2602
    
    # An ID we got from them in the follow request
    their_follow_id = "https://social.coop/a55b9a8e-3ffb-4f97-8fce-e3731e2ed988"
    
    object = {
      "@context": [
            "https://www.w3.org/ns/activitystreams",
            "https://w3id.org/security/v1"
          ],
      "type": "Accept",
      "id": their_follow_id,
      "object": remote_actor_url
    }
        
    sign_and_send(participant_id, remote_actor, object, 'respond_to_follow')
    
  end
    
end