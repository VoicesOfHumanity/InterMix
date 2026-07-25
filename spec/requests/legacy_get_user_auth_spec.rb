# Coverage for the API_LEGACY_AUTH stopgap that unbreaks mobile auto-login.
#
# The app persists only userId (never the auth_token), so on every cold start it
# calls GET /api/get_user?id=N with no token. api_claimed_user_id only reads
# :user_id, so that request fell through to 401 even with API_LEGACY_AUTH=1 --
# users were silently logged out on each app launch. The stopgap lets :id stand in
# for :user_id on get_user ONLY, and only while the flag is on.
#
# NOTE: participants is a MyISAM table and does not roll back; clean up explicitly.
require 'rails_helper'

RSpec.describe 'get_user legacy auth stopgap', type: :request do
  API_CODE_LGU = 'Xe6tsdfasf'

  let!(:cleanup) { [] }
  after { cleanup.each { |r| r.destroy rescue nil } }

  let(:participant) do
    p = Participant.create!(first_name: 'Legacy', last_name: 'User',
                            email: "lgu_#{rand(1e12).to_i}@example.com", password: 'password1')
    p.ensure_authentication_token!
    cleanup << p
    p
  end

  def with_legacy_auth(value)
    previous = ENV['API_LEGACY_AUTH']
    ENV['API_LEGACY_AUTH'] = value
    yield
  ensure
    ENV['API_LEGACY_AUTH'] = previous
  end

  describe 'with API_LEGACY_AUTH=1 (current production setting)' do
    it 'authenticates the tokenless auto-login call and returns the user' do
      with_legacy_auth('1') do
        get "/api/get_user?id=#{participant.id}&x=#{API_CODE_LGU}"
      end
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['status']).to eq('success')
      expect(body['user']['id']).to eq(participant.id)
    end

    it 'still 401s when no id at all is supplied' do
      with_legacy_auth('1') { get "/api/get_user?x=#{API_CODE_LGU}" }
      expect(response.status).to eq(401)
    end

    it 'still 401s for an id that is not a participant' do
      with_legacy_auth('1') { get "/api/get_user?id=999999999&x=#{API_CODE_LGU}" }
      expect(response.status).to eq(401)
    end

    it 'does NOT let :id stand in for a participant on other actions' do
      # :id means an item/community elsewhere, so it must not authenticate anyone.
      with_legacy_auth('1') do
        post '/api/importance', params: { x: API_CODE_LGU, id: participant.id, item_id: 1, importance: 1 }
      end
      expect(response.status).to eq(401)
    end
  end

  describe 'with the flag off (the eventual end state)' do
    it 'rejects the tokenless auto-login call' do
      with_legacy_auth('0') do
        get "/api/get_user?id=#{participant.id}&x=#{API_CODE_LGU}"
      end
      expect(response.status).to eq(401)
    end

    it 'still accepts a real auth_token' do
      with_legacy_auth('0') do
        get "/api/get_user?id=#{participant.id}&auth_token=#{participant.authentication_token}&x=#{API_CODE_LGU}"
      end
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['user']['id']).to eq(participant.id)
    end
  end
end
