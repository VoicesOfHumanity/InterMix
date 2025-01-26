
require File.dirname(__FILE__)+'/cron_helper'

ActionMailer::Base.delivery_method = :postmark
ActionMailer::Base.postmark_settings = { api_key: Rails.application.credentials.postmark[:api_key] }

recip = "ffunch@cr8.com"
msubject = "Test email from Ruby script"
html_content = "<h1>Test email from Ruby script</h1>"
cdata = {}

email = SystemMailer.generic(SYSTEM_SENDER, recip, msubject, html_content, cdata)

begin
  puts "sending email to #{recip}"
  email.deliver
  message_id = email.message_id
  puts "message_id: #{message_id}"
rescue Exception => e
  puts "Error sending email to #{recip}: #{e.message}"
end