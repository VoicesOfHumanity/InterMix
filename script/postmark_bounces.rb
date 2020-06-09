require File.dirname(__FILE__)+'/cron_helper'
require 'net/http'
require 'openssl'

#curl "https://api.postmarkapp.com/bounces?type=HardBounce&inactive=true&count=50&offset=0" \
#  -X GET \
#  -H "Accept: application/json" \
#  -H "X-Postmark-Server-Token: cc26728f-ff0c-403f-9c4a-be1b0c92d8bb"

uri = URI("https://api.postmarkapp.com/bounces?type=HardBounce&inactive=true&count=50&offset=0")

#req = Net::HTTP::Get.new(uri)
#req['X-Postmark-Server-Token'] = "cc26728f-ff0c-403f-9c4a-be1b0c92d8bb"
#req['Accept'] = "application/json"

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new(uri)
request['X-Postmark-Server-Token'] = "cc26728f-ff0c-403f-9c4a-be1b0c92d8bb"
request['Accept'] = "application/json"

response = http.request(request)
#puts response.read_body

=begin
{
  "TotalCount": 253,
  "Bounces": [
    {
      "ID": 692560173,
      "Type": "HardBounce",
      "TypeCode": 1,
      "Name": "Hard bounce",
      "Tag": "Invitation",
      "MessageID": "2c1b63fe-43f2-4db5-91b0-8bdfa44a9316",
      "ServerID": 23,
      "Description": "The server was unable to deliver your message (ex: unknown user, mailbox not found).",
      "Details": "action: failed\r\n",
      "Email": "anything@blackhole.postmarkapp.com",
      "From": "sender@postmarkapp.com",
      "BouncedAt": "2014-01-15T16:09:19.6421112-05:00",
      "DumpAvailable": false,
      "Inactive": false,
      "CanActivate": true,
      "Subject": "SC API5 Test"
    },
    {
      "ID": 676862817,
      "Type": "HardBounce",
      "TypeCode": 1,
      "Name": "Hard bounce",
      "Tag": "Invitation",
      "MessageID": "623b2e90-82d0-4050-ae9e-2c3a734ba091",
      "ServerID": 23,
      "Description": "The server was unable to deliver your message (ex: unknown user, mailbox not found).",
      "Details": "smtp;554 delivery error: dd This user doesn't have a yahoo.com account (vicelcown@yahoo.com) [0] - mta1543.mail.ne1.yahoo.com",
      "Email": "vicelcown@yahoo.com",
      "From": "sender@postmarkapp.com",
      "BouncedAt": "2013-10-18T09:49:59.8253577-04:00",
      "DumpAvailable": false,
      "Inactive": true,
      "CanActivate": true,
      "Subject": "Production API Test"
    }
  ]
}
=end

# json
data = JSON.parse(response.body)

#puts data

total_count = data["TotalCount"]
bounces = data["Bounces"]

puts "#{total_count} bounces received"

num_removed = 0

bounces.each do |bounce|
  email = bounce["Email"]
  bounce_type = bounce["Type"]
  inactive = bounce["Inactive"]
  
  participants = Participant.where(email: email, no_email: false)
  for p in participants
    p.no_email = true
    p.no_email_reason = bounce_type
    p.save
    puts "Participant:#{p.id} set to no_email Email: #{email} Type:#{bounce_type}"
    num_removed += 1
  end
  
end

puts "#{num_removed} users set to no_email"

