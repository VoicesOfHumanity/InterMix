class ActivitypubController < ApplicationController

  def acct
    # Show info for a user, after accessing something like: https://intermix.test:3002/acct/ff1888
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
    
    account_uniq = params[:acct_id]

    @account = Participant.find_by_account_uniq(account_uniq)



    @account_url = "https://#{BASEDOMAIN}/acct/#{@account.account_uniq}"
    
    @inbox_url = "https://#{BASEDOMAIN}/acct/#{@account.account_uniq}/inbox"
    
    results = {
      	"@context" => [
      		"https://www.w3.org/ns/activitystreams",
      		"https://w3id.org/security/v1"
      	],
        "id" => @account_url,
        "type" => "Person",
        "preferredUsername" => @account.account_uniq,
        "inbox" => @inbox_url,
        "publicKey" => {
          "id" => "",
          "owner" => @account_url,
          "publicKeyPem" => ""
        } 
    }
    
    results_json = results.to_json
    
    expires_in 3.days, public: true
    render json: results_json, content_type: 'application/jrd+json'
  end
  
  def inbox
    
  end


end


