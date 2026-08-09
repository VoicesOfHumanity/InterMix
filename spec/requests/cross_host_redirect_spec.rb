# Regression coverage for a production 500 (2026-08):
#   ActionController::Redirecting::UnsafeRedirectError in passwords#new —
#   Unsafe redirect to "https://intermix.cr8.com/me/profile/meta"
# DeviseController#require_no_authentication bounces an already-signed-in
# participant with a bare `redirect_to after_sign_in_path_for(resource)`, and
# this app's after_sign_in_path_for returns an absolute "https://BASEDOMAIN/..."
# URL. There is no call site to mark allow_other_host: true, so ApplicationController
# now allows redirects to the app's OWN hosts and nothing else.
# NOTE: participants are MyISAM and do not roll back, so clean up explicitly.
require 'rails_helper'

RSpec.describe 'Cross-host redirects to the app own hosts', type: :request do
  let!(:cleanup) { [] }

  #-- no first_name => has_required is false => after_sign_in_path_for takes the
  #-- "https://#{BASEDOMAIN}/me/profile/meta" branch, which is what blew up.
  let!(:participant) do
    p = Participant.new(email: "xhost#{rand(1e9).to_i}@example.com",
                        password: 'testtest', password_confirmation: 'testtest')
    p.save!
    p.update_columns(status: 'active', confirmed_at: Time.now, first_name: nil)
    cleanup << p
    p
  end

  before { login_as(participant, scope: :participant) }

  after do
    Warden.test_reset!
    cleanup.each { |r| r.destroy rescue nil }
  end

  #-- another of our own hosts, not BASEDOMAIN: a group/dialog subdomain, or
  #-- plain intermix.org next to voh.intermix.org in production.
  let(:other_own_host) { "voh.#{ROOTDOMAIN}" }

  it 'does not raise on the forgot-password page (the reported crash)' do
    host! other_own_host
    expect { get '/participants/password/new' }.not_to raise_error
    expect(response.status).to eq(302)
    expect(response.headers['Location']).to eq("https://#{BASEDOMAIN}/me/profile/meta")
  end

  it 'does not raise on the sign-in page' do
    host! other_own_host
    expect { get '/participants/sign_in' }.not_to raise_error
    expect(response.status).to eq(302)
  end

  it 'does not raise on the sign-up page' do
    host! other_own_host
    expect { get '/participants/sign_up' }.not_to raise_error
    expect(response.status).to eq(302)
  end

  it 'still redirects normally when already on BASEDOMAIN' do
    host! BASEDOMAIN
    get '/participants/password/new'
    expect(response.status).to eq(302)
    expect(response.headers['Location']).to eq("https://#{BASEDOMAIN}/me/profile/meta")
  end

  describe 'the own-host test itself' do
    let(:controller) { ApplicationController.new }
    def own?(url) = controller.send(:own_host_url?, url)

    it 'accepts our own hosts' do
      expect(own?("https://#{BASEDOMAIN}/me/profile/meta")).to be true
      expect(own?("https://#{ROOTDOMAIN}/join")).to be true
      expect(own?("//#{BASEDOMAIN}/join")).to be true
      expect(own?("//somegroup.#{ROOTDOMAIN}/")).to be true
      expect(own?("HTTPS://#{BASEDOMAIN.upcase}/x")).to be true
    end

    it 'rejects everything else, so those still raise' do
      expect(own?('https://evil.com/phish')).to be false
      expect(own?("https://evil.com/?x=#{ROOTDOMAIN}")).to be false
      #-- the lookalike suffix trap: notintermix.test must not match intermix.test
      expect(own?("https://not#{ROOTDOMAIN}/x")).to be false
      expect(own?("https://#{ROOTDOMAIN}.evil.com/x")).to be false
      expect(own?('/me/profile/meta')).to be false
      expect(own?(nil)).to be false
      expect(own?({ controller: 'front', action: 'index' })).to be false
      expect(own?('http://[bad uri')).to be false
    end
  end
end
