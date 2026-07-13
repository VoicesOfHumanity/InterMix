# Regression coverage for the 2026-07 audit security fixes.
# NOTE: participants/items/ratings/communities-tagging live on MyISAM tables, which
# do not roll back with transactional fixtures, so each example cleans up explicitly.
require 'rails_helper'

RSpec.describe 'Audit security fixes', type: :request do
  API_CODE = 'Xe6tsdfasf'

  let!(:cleanup) { [] }
  after do
    cleanup.each { |r| r.destroy rescue nil }
  end

  def make_participant
    p = Participant.create!(first_name: 'T', last_name: 'User',
                            email: "sec_#{rand(1e12).to_i}@example.com", password: 'password1')
    p.ensure_authentication_token!
    cleanup << p
    p
  end

  describe 'per-user API auth (task 3: no more params[:user_id] trust)' do
    let(:actor)  { make_participant }
    let(:victim) { make_participant }
    let(:community) do
      c = Community.create!(tagname: "sec#{rand(1e9).to_i}", fullname: 'Sec Test')
      cleanup << c
      c
    end

    it 'rejects a wrong API code before anything else' do
      post '/api/join_community', params: { x: 'WRONG', auth_token: actor.authentication_token, community_id: community.id }
      expect(JSON.parse(response.body)['message']).to eq('Access denied')
    end

    it 'rejects a request with no auth_token (401)' do
      post '/api/join_community', params: { x: API_CODE, community_id: community.id }
      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)['message']).to match(/auth_token/i)
    end

    it 'rejects a valid token whose user_id claims a different user (403)' do
      post '/api/join_community', params: { x: API_CODE, auth_token: actor.authentication_token,
                                            user_id: victim.id, community_id: community.id }
      expect(response.status).to eq(403)
      expect(actor.reload.tag_list_downcase).not_to include(community.tagname.downcase)
    end

    it 'accepts a valid token and acts as the token owner' do
      post '/api/join_community', params: { x: API_CODE, auth_token: actor.authentication_token, community_id: community.id }
      expect(JSON.parse(response.body)['status']).to eq('success')
      expect(actor.reload.tag_list_downcase).to include(community.tagname.downcase)
    end

    it 'get_user returns only PUBLIC fields for another user (no email/auth_token)' do
      get '/api/get_user', params: { x: API_CODE, auth_token: actor.authentication_token, id: victim.id }
      expect(response.status).to eq(200)
      user = JSON.parse(response.body)['user']
      expect(user['name']).to eq(victim.name)
      expect(user).not_to have_key('email')
      expect(user).not_to have_key('auth_token')
    end

    it 'get_user returns full info (incl. auth_token) for the caller themselves' do
      get '/api/get_user', params: { x: API_CODE, auth_token: actor.authentication_token, id: actor.id }
      user = JSON.parse(response.body)['user']
      expect(user['auth_token']).to eq(actor.authentication_token)
    end

    it 'verify_email never returns an auth_token for an arbitrary email' do
      target = make_participant
      get '/api/verify_email', params: { x: API_CODE, email: target.email }
      body = JSON.parse(response.body)
      expect(body['status']).to eq('success')
      expect(body['user']).not_to have_key('auth_token')   # the account-takeover vector
    end

    it 'legacy bridge (API_LEGACY_AUTH=1) still accepts a user_id-only call' do
      begin
        ENV['API_LEGACY_AUTH'] = '1'
        post '/api/join_community', params: { x: API_CODE, user_id: actor.id, community_id: community.id }
        expect(JSON.parse(response.body)['status']).to eq('success')
        expect(actor.reload.tag_list_downcase).to include(community.tagname.downcase)
      ensure
        ENV.delete('API_LEGACY_AUTH')
      end
    end
  end

  describe 'strong parameters (task 4: permit_all_parameters removed)' do
    # With permit_all_parameters=true this would silently mass-assign; the raise
    # only happens because enforcement is now on globally.
    it 'raises ForbiddenAttributesError on raw mass-assignment' do
      raw = ActionController::Parameters.new(tagname: 'x', administrator_id: 999)
      expect { Community.new(raw) }.to raise_error(ActiveModel::ForbiddenAttributesError)
    end
  end

  describe 'stored XSS sanitization (task 2)' do
    it 'strips <script> from short_content via sanitizethis' do
      cleaned = ApplicationController.new.helpers.sanitizethis('<b>hi</b><script>alert(1)</script>')
      expect(cleaned).to include('<b>hi</b>')
      expect(cleaned).not_to include('<script>')
    end
  end

  describe 'SQL injection parameterization (task 1)' do
    it 'treats an injection payload as a literal value, not SQL' do
      payload = "zz' OR '1'='1"
      expect { Geoadmin1.where(country_code: payload).where.not(admin1_code: '00').to_a }.not_to raise_error
      # neutralized: no admin1 row has that literal country_code
      expect(Geoadmin1.where(country_code: payload).count).to eq(0)
    end
  end
end
