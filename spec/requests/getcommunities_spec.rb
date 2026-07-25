# /front/getcommunities?which_com=my&participant_id=N used to 404 for any participant_id
# that did not exist, because the action called Participant.find (raises RecordNotFound)
# instead of find_by_id. The mobile app's Communities tab hung on that 404. Only which_com=my
# was affected — every other value skips the branch entirely, which is why participant_id=0
# and which_com=other/ungoals kept returning 200.
#
# NOTE: participants/communities/taggings are MyISAM and do not roll back; clean up explicitly.
require 'rails_helper'

RSpec.describe '/front/getcommunities', type: :request do
  let!(:cleanup) { [] }
  after { cleanup.reverse.each { |r| r.destroy rescue nil } }

  def make_participant(tags: [])
    p = Participant.create!(first_name: 'GC', last_name: 'User',
                            email: "gc_#{rand(1e12).to_i}@example.com", password: 'password1')
    tags.each { |t| p.tag_list.add(t) }
    p.save! if tags.any?
    cleanup << p
    p
  end

  describe 'which_com=my' do
    it 'returns an empty list (not 404) for a participant_id that does not exist' do
      missing = Participant.maximum(:id).to_i + 100_000
      get "/front/getcommunities?which_com=my&participant_id=#{missing}"
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns an empty list for a real participant with no community tags' do
      get "/front/getcommunities?which_com=my&participant_id=#{make_participant.id}"
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns the participant's own communities" do
      tagname = "gctag#{rand(1e12).to_i}"
      community = Community.create!(tagname: tagname, fullname: 'GC Community')
      cleanup << community
      participant = make_participant(tags: [tagname])

      get "/front/getcommunities?which_com=my&participant_id=#{participant.id}"
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body.map { |c| c['tagname'] }).to include(tagname)
    end

    it 'is a 200 for participant_id=0 (branch is skipped)' do
      get '/front/getcommunities?which_com=my&participant_id=0'
      expect(response.status).to eq(200)
    end
  end

  describe 'the other which_com values still work' do
    %w[other ungoals more major all sustdev].each do |which|
      it "returns 200 for which_com=#{which} even with an unknown participant_id" do
        missing = Participant.maximum(:id).to_i + 100_000
        get "/front/getcommunities?which_com=#{which}&participant_id=#{missing}"
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to be_an(Array)
      end
    end
  end
end
