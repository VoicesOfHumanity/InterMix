class CustomDeviseMailer < Devise::Mailer
  default from: 'questions@intermix.org'
  layout 'mailer'

  # Ensure the mailer uses the Postmark delivery method
  def headers_for(action, opts)
    super.merge!(delivery_method: :postmark, postmark_settings: { api_key: Rails.application.credentials.postmark[:api_key] })
  end
end