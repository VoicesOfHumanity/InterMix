require 'uri'
require 'openssl'
require "base64"

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
      Rails.logger.info("activitypub#record_request error: #{e}")
    end
  end
  
  def record_response(results_json)
    # update the record with the results, if any
    @api_request.response_body = results_json
    @api_request.participant_id = @account.id if @account
    @api_request.processed = true
    @api_request.save
  end
  
  def is_valid_request(req)
    # Determine whether a request we received is properly signed
    return false if not req

    http_signature = nil
    http_digest = nil
    
    request_headers = req.request_headers
    if not request_headers
      puts "didn't get any headers"
      return false
    end
    
    if request_headers.class == String
      begin
        request_headers = JSON.parse(request_headers)
      rescue
        puts "request headers didn't seem to be in the right format"
        return false
      end
    end  
    
    if request_headers.has_key?('HTTP_SIGNATURE')
      http_signature = request_headers['HTTP_SIGNATURE']
    else
      puts "http signature missing"
      return false
    end
    
    if request_headers.has_key?('HTTP_DIGEST')
      http_digest = request_headers['HTTP_DIGEST']
      # Something like:
      # SHA-256=pLOT+MzO99oXgCesq+iNSlL+q9QVulnavBrAuVScyVQ=
    else
      puts "http digest missing"
      return false
    end

    # Might look something like this:
    # keyId="https://social.coop/users/ming#main-key",algorithm="rsa-sha256",headers="(request-target) host date digest content-type",signature="IQ+WO+k1ih5VuykJzOLdDWqmSUl37dtkK6cwEzjyvHBqQbVV6K/Vn9iLdOZ9sRSdrNpFvlTti3EeIIfVBNIOmJ77nKjpzl0LaKysksu65Y8XjzD0MPrIilgji29qg8XEW5m2ffnGHn1V0BUaVutCsuku8xswz2hDF3YbWR3v8NOlOdzpB+CItbr3LbZJfgrxilyBitQECg+5PP7GPJxv6tg/6s8aZs23MxQCSod/wvrntmOgu+oiLBSwzG6iLwDAeQq7K0NQSg5Uc1IPI71WhP53dycFh/RKn06/O0vgLxfCvRZoyKddMd4qP4B2LkHKn19cwdX+5Y1z2N5adho4Nw=="
    
    key_id = nil
    algorithm = nil
    header_list = nil
    signature = nil
    
    sigparts = http_signature.split(',')
    for part in sigparts
      m = part.match /([^=]+)="([^"]+)"/      
      fld = m[1]
      val = m[2]

      key_id = val if fld == 'keyId'
      algorithm = val if fld == 'algorithm'
      header_list = val if fld == 'headers'
      signature = val if fld == 'signature'
    end
    
    if not signature
      puts "there was no signature in the http_signature section"
      return false
    end
    
    # Check digest
    
    # Something like:
    #SHA-256=NNfmbex8OJE3kL4ykrkAuGmFn/61yiXWbFAq5q1bIeA=
    m = http_digest.match /([^=]+)=(\S+)$/      
    dig_type = m[1]
    dig_val = m[2]
    
    dig_calc = Base64.strict_encode64((OpenSSL::Digest::SHA256.new).digest(req.request_body))
    
    if dig_calc == dig_val
      puts "the digest is correct"
    else
      puts "The calculated digest #{dig_calc} doesn't matter the given digest #{dig_val}"
      return false
    end
    
    return true
    
    # WE ALDO NEED TO VALIDATE THE SIGNATURE!

  end
    
  def sign_and_send(from_id, to_remote_actor, object, our_function)
    # Send something to a remote user's inbox
    # inspired by https://glitch.com/edit/#!/glib-cheerful-addition?path=routes%2Finbox.js%3A1%3A0
    # and https://blog.joinmastodon.org/2018/06/how-to-implement-a-basic-activitypub-server/
    # We're signing the message with the private key of the sender
    
    inbox_url = to_remote_actor.inbox_url
    if not inbox_url or not inbox_url =~ /^http/
      Rails.logger.info "activitypub#sign_and_send No inbox URL for #{to_remote_actor.account}"
      return false
    end
    Rails.logger.info "activitypub#sign_and_send inbox url: #{inbox_url}"
    
    if not defined?(current_participant) or from_id != current_participant.id
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
    
    return @api_send
  end

  def normalize_actor(actor_uniq)
    # clean up an actor id a little bit
    actor_uniq.strip!.downcase!
    actor_uniq[0] = '' if actor_uniq[0] == '@'
    actor_uniq
  end
  
  def get_remote_actor(actor_uniq_or_url)
    # Get information about a remote account, either by asking, or from our cache
    # We get either something like ming@social.coop pr @ming@social.coop
    # or a URL like https://social.coop/users/ming    
    
    actor_uniq_or_url.strip!
    
    if actor_uniq_or_url[0] == '@'
      actor_uniq_or_url = actor_uniq_or_url[1,100]
    end
    
    actor_uniq = ''
    actor_url = ''
    
    if actor_uniq_or_url[0,4] == 'http'
      actor_url = actor_uniq_or_url
      remote_actor = RemoteActor.find_by_account_url(actor_url)
    elsif actor_uniq_or_url.include?('@')
      actor_uniq = actor_uniq_or_url
      remote_actor = RemoteActor.find_by_account(actor_uniq)
    else
      return nil
    end    
    
    if remote_actor and remote_actor.last_fetch >= Date.today - 7
      get_new = false
      Rails.logger.info("activitypub#get_remote_actor already have recent info for #{actor_uniq}")
    else
      get_new = true
      if remote_actor
        Rails.logger.info("activitypub#get_remote_actor we have info for #{actor_uniq}, but not recent enough")
      else
        Rails.logger.info("activitypub#get_remote_actor we have no info for #{actor_uniq}")
      end
    end    
    if get_new
      if actor_url == '' and actor_uniq != ''
        actor_url = get_actor_url_by_webfinger(actor_uniq)
      end
      if actor_url.to_s != ''

        Rails.logger.info("activitypub#get_remote_actor getting #{actor_url}")

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
            Rails.logger.info("activitypub#get_remote_actor response: #{response.code}")
          else
            Rails.logger.info("activitypub#get_remote_actor no reponse")
            return nil
          end
          
          # Mastodon redirects https://social.coop/users/ming to https://social.coop/@ming
          
          if response.code.to_i == 301 or response.code.to_i == 302
            actor_url = response['location']
            Rails.logger.info("activitypub#get_remote_actor redirecting to #{actor_url}")
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
          Rails.logger.info("activitypub#get_remote_actor no reponse")
          return nil          
        elsif response.code.to_i == 301 or response.code.to_i == 302
          Rails.logger.info("activitypub#get_remote_actor too many redirections")
          return nil
        end
        
        if response.code.to_i == 200
          body = response.body
          #Rails.logger.info("activitypub#get_remote_actor body: #{body}")     
          begin
            data = JSON.parse(body)
          rescue
            Rails.logger.info("activitypub#get_remote_actor couldn't read any json data}")
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
            Rails.logger.info("activitypub#get_remote_actor unexpected json data}")
            return nil
          end
        else
          Rails.logger.info("activitypub#get_remote_actor got response code #{response.code} to #{actor_url}")
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
      Rails.logger.info("activitypub#get_actor_url_by_webfinger body: #{body}")
      # From Mastodon:
      # {"subject":"acct:ming@social.coop","aliases":["https://social.coop/@ming","https://social.coop/users/ming"],"links":[{"rel":"http://webfinger.net/rel/profile-page","type":"text/html","href":"https://social.coop/@ming"},{"rel":"self","type":"application/activity+json","href":"https://social.coop/users/ming"},{"rel":"http://ostatus.org/schema/1.0/subscribe","template":"https://social.coop/authorize_interaction?uri={uri}"}]}
      begin
        data = JSON.parse(body)
      rescue
        Rails.logger.info("activitypub#get_actor_url_by_webfinger couldn't read any json data}")
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
        Rails.logger.info("activitypub#get_actor_url_by_webfinger unexpected json data}")
      end
    else
      Rails.logger.info("activitypub#get_actor_url_by_webfinger got response code #{response.code} to #{wurl}")
      return ''
    end
  
    return actor_url
  end

  def respond_to_follow(remote_actor, participant, their_follow_id, api_request_id)
    #-- Record and answer a follow request from the outside. We'll probably want to do that automatically right away

    #remote_actor_url = remote_actor.account_url   # https://social.coop/users/ming
    #their_follow_id = "https://social.coop/a55b9a8e-3ffb-4f97-8fce-e3731e2ed988"

    # Record the follow
    follow = Follow.create(
      followed_id: participant.id,
      following_remote_actor_id: remote_actor.id,
      following_fulluniq: remote_actor.account,
      int_ext: 'ext',
      remote_reference: their_follow_id,
      accepted: false
    )
    
    # We will automatically send back an accept
    object = {
      "@context": [
            "https://www.w3.org/ns/activitystreams",
            "https://w3id.org/security/v1"
          ],
      "type": "Accept",
      "id": their_follow_id,
      "object": remote_actor.account_url
    }
        
    req = sign_and_send(participant_id, remote_actor, object, 'respond_to_follow')
    
    if req
      follow.accepted = true
      follow.accept_record_id = req.id
      follow.save
    end
    
    # NB: We should also send an email to our user
    
  end
  
  def repond_to_accept_follow(from_remote_actor, to_participant, ref_id, api_request_id)
    # We've received an acceptance of our following of a remote actor
    if not from_remote_actor or not to_participant
      return false
    end
    
    follow = Follow.where(following_remote_actor_id: from_remote_actor.id, followed_id: to_participant.id).first
    if follow
      if not follow.accepted
        follow.accepted = true
        follow.accept_record_id = api_request_id
        follow.save
      end
    end  
    
    return true
  end
  
  def respond_to_note(from_remote_actor, to_participant, ref_id, api_request_id, content, date)
    #-- Receive a note. Assuming it to be a personal message at the moment
    if not from_remote_actor or not to_participant
      return false
    end
        
    message = Message.create(
      from_remote_actor_id: from_remote_actor.id,
      to_participant_id: to_participant.id,
      subject: 'message',
      message: content,
      sendmethod: 'activitypub',
      sent: true,
      sent_at: date,
      int_ext: 'ext',
      email_sent: false,
      received_json: object
    )

    # NB: We should also send an email to our user
    
    return true    
  end
  
  def respond_to_delete_actor(from_remote_actor)
    #-- A remote account has disappared. Let's remove it from follows
    if not from_remote_actor
      return false
    end
    remote_actor_id = from_remote_actor.id
    
    numdone = 0
    follows = Follow.where("followed_remote_actor_id=#{remote_actor_id} or following_remote_actor_id=#{remote_actor_id}")
    for follow in follows
      follow.destroy
      numdone += 1
    end
    puts "#{numdone} follow records removed"
    
    return true
  end
  
  def get_request_data(obj)
    # Given a received object, try to figure out what it is
    
    # atype: the type of activity: Follow, Accept, Create
    # otype: the type of object: Follow, Note, Actor
    # rtype: our code for what's happening. follow_request, accept_follow, note, etc.
    
    data = {
      'atype': '',
      'from_actor_url': '',
      'to_actor_url': '',
      'object': nil,
      'otype': '',
      'rtype': '',
      'status': '',
      'error': '',
      'from_remote_actor': nil,
      'to_participant': nil,
      'ref_id': nil,
      'content': nil,
      'date': nil
    }
    
    if not obj.has_key?('type') or not obj.has_key?('actor') or not obj.has_key?('object')
      data['status'] = 'error'
      data['error'] = "Don't recognize this as an activitypub request"
      return data
    end
    
    if obj.has_key?('published')      # 2021-05-11T17:31:34Z
      data['date'] = Date.parse(obj['published'])
    end
    
    atype = obj['type']
    data['atype'] = atype
    data['from_actor_url'] = obj['actor']
    object = obj['object']
    data['object'] = object
    
    # The object might be a dix or just a string
    if object.class == String
      # "object":"https://intermix.cr8.com/u/ff2602"
      if obj.has_key?('to')
        data['to_actor_url'] = obj['to']
      else
        data['to_actor_url'] = object
      end
      otype = 'actor'
    elsif object.class == Hash and object.has_key?('type')
      otype = object['type']
      if object.has_key?('to')
        data['to_actor_url'] = object['to']
      elsif obj.has_key?('to')
        data['to_actor_url'] = obj['to']
      elsif object.has_key?('actor')
        data['to_actor_url'] = object['actor']
      end
      if object.has_key?('id')
        data['ref_id'] = object['id']
      end
      if object.has_key?('content')
        data['content'] = object['content']
      end
      if object.has_key?('published') and not data['date']
        data['date'] = Date.parse(object['published'])
      end
      
    else
      data['status'] = 'error'
      data['error'] = "Can't identify any target object"
      return data
    end
    data['otype'] = otype

    if data['to_actor_url'].class == Array
      # We might have gotten a list of recipients. Hopefully just one
      # NB: WE NEED TO BE ABLE TO DEAL WITH MULTIPLE RECIPIENTS
      if data['to_actor_url'].length == 1
        data['to_actor_url'] = data['to_actor_url'][0]
      end
    end
        
    if not data['ref_id'] and obj.has_key?('id')
      data['ref_id'] = obj['id']
    end
          
    if atype.downcase == 'follow'
      # Somebody wants to follow us
      # Need actor and object
      rtype = 'follow_request'
    elsif atype.downcase == 'accept' and otype.downcase == 'follow'
      # Accepting our follow. We should have gotten ID we gave them
      rtype = 'accept_follow'
    elsif atype.downcase == 'create' and otype.downcase == 'note'
      # Sending us a note
      rtype = 'note'
    elsif atype.downcase == 'delete' and otype.downcase == 'actor'
      # A remote account has been removed
      rtype = 'delete_actor'
    else
      data['error'] = "Don't know what to do with that yet"
      rtype = '?'
    end
    data['rtype'] = rtype
    
    data['from_remote_actor'] = get_remote_actor(data['from_actor_url'])
    
    if data['to_actor_url'] != ''
      # https://intermix.cr8.com/u/ff2602
      begin
        url = URI.parse(data['to_actor_url'])
      rescue
        puts "no url from to_actor_url:#{data['to_actor_url']}"
        url = nil
      end
      if url
        parr = url.path.split('/')
        last = parr.last
        xarr = last.split('?')
        if xarr.length > 0
          username = xarr[0]
        else
          username = last
        end
        participant = Participant.find_by_account_uniq(username)
        data['to_participant'] = participant if participant
      end
    end
    
    if not data['from_remote_actor']
      data['status'] = 'error'
      data['error'] = "Couldn't identify remote actor"
    elsif not data['to_participant']
      data['status'] = 'error'
      data['error'] = "Couldn't identify target user"
    else  
      data['status'] = 'ok'
    end
    
    return data
  end
  
  def obj_from_request(req)
    # Extract the object from the json we got
    if not req.request_body
      Rails.logger.info("activity_pub#obj_from_request no request body")
      puts "no request body"
      return nil
    end
    #data = JSON.parse(req.request_body)
    begin
      data = JSON.parse(req.request_body)
    rescue
      Rails.logger.info("activity_pub#obj_from_request couldn't read any json data")
      puts "no json"
      puts req.request_body.inspect
      return nil
    end
    Rails.logger.info("activitypub#obj_from_request data returned: #{data}")
    return data
  end
    
end