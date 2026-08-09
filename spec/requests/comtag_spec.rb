# Regression coverage for a production 500 in profiles#comtag (2026-08):
#   NoMethodError: undefined method `downcase' for nil:NilClass
# /me/comtag is only ever linked with a ?comtag=..., but a signed-in browser
# hitting it bare (prefetch, stale bookmark, scanner) reached the leave branch
# with comtag == nil and blew up comparing it against each of the user's tags.
# NOTE: participants/tags/taggings are MyISAM and do not roll back, so clean up
# explicitly.
require 'rails_helper'

RSpec.describe 'profiles#comtag with a missing community tag', type: :request do
  let!(:cleanup) { [] }

  let!(:participant) do
    p = Participant.new(email: "comtag#{rand(1e9).to_i}@example.com",
                        password: 'testtest', password_confirmation: 'testtest')
    p.save!
    p.update_columns(status: 'active', confirmed_at: Time.now)
    #-- the reported crash was comparing each of the user's tags against the
    #-- missing one, so the participant has to carry at least one tag
    p.tag_list.add('existingtag')
    p.save!
    cleanup << p
    p
  end

  before { login_as(participant, scope: :participant) }

  after do
    Warden.test_reset!
    cleanup.each { |r| r.destroy rescue nil }
  end

  it 'returns 400 when comtag is absent entirely' do
    expect { get '/me/comtag' }.not_to raise_error
    expect(response.status).to eq(400)
  end

  it 'returns 400 for ?comtag with no value (nil param)' do
    expect { get '/me/comtag?comtag&which=leave' }.not_to raise_error
    expect(response.status).to eq(400)
  end

  it 'returns 400 for ?comtag= (blank value)' do
    get '/me/comtag?comtag=&which=join'
    expect(response.status).to eq(400)
  end

  it 'returns 400 for a non-string comtag param' do
    expect { get '/me/comtag?comtag[]=love&which=join' }.not_to raise_error
    expect(response.status).to eq(400)
  end

  it 'leaves a free-form tag that has no community behind it' do
    participant.tag_list.add('nosuchcommunity')
    participant.save!

    expect { get '/me/comtag?comtag=nosuchcommunity&which=leave' }.not_to raise_error
    expect(response.status).to eq(200)
    expect(participant.reload.tag_list).not_to include('nosuchcommunity')
  end

  it 'still joins a real community' do
    community = Community.create!(tagname: "comtag#{rand(1e9).to_i}", fullname: 'Comtag Test')
    cleanup << community

    get "/me/comtag?comtag=#{community.tagname}&which=join"
    expect(response.status).to eq(200)
    expect(response.body).to eq('ok')
    expect(participant.reload.tag_list).to include(community.tagname)
  end

  it 'still leaves a real community' do
    community = Community.create!(tagname: "comtag#{rand(1e9).to_i}", fullname: 'Comtag Test')
    cleanup << community
    participant.tag_list.add(community.tagname)
    participant.save!

    get "/me/comtag?comtag=#{community.tagname}&which=leave"
    expect(response.status).to eq(200)
    expect(participant.reload.tag_list).not_to include(community.tagname)
  end
end
