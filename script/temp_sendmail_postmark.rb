
require File.dirname(__FILE__)+'/cron_helper'

ActionMailer::Base.delivery_method = :postmark
ActionMailer::Base.postmark_settings = { api_key: Rails.application.credentials.postmark[:api_key] }

recip = "ffunch@cr8.com"
msubject = "Test email from Ruby script"
html_content = "<h1>Test email from Ruby script</h1>"
cdata = {}

email = SystemMailer.generic(SYSTEM_SENDER, recip, msubject, html_content, cdata)


require File.dirname(__FILE__)+'/cron_helper'

ActionMailer::Base.delivery_method = :postmark
ActionMailer::Base.postmark_settings = { api_key: Rails.application.credentials.postmark[:api_key] }

api_key = Rails.application.credentials.postmark[:api_key]
puts "api_key: #{api_key}"

recip = "ffunch@gmail.com"
msubject = "Test email from Ruby script"
html_content = "<h1>Test email from Ruby script</h1>"
cdata = {}

#email = SystemMailer.generic(SYSTEM_SENDER, recip, msubject, html_content, cdata)

message_hash = {
  from: SYSTEM_SENDER,
  to: recip,
  subject: msubject,
  html_body: html_content
}

begin
  response = Postmark::ApiClient.new(api_key).deliver(message_hash)
  puts "response: #{response.inspect}"
rescue Postmark::Error => e
  puts "Postmark API error: #{e.message}"
end

# response = Postmark::ApiClient.new(Rails.application.credentials.postmark[:api_key]).deliver_with_template(
#   from: SYSTEM_SENDER,
#   to: recip,
#   template_id: 'template-id',
#   template_model: { name: 'John' }
# )
