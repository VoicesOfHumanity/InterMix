# Regression coverage for two crawler-triggered 500s seen in production 2026-07:
#   - ActionView::MissingTemplate in communities#fronttag for formats [:zip]
#   - NoMethodError (strip on nil) in well_known#webfinger
# NOTE: communities is a MyISAM table and does not roll back, so clean up explicitly.
require 'rails_helper'

RSpec.describe 'Malformed crawler requests', type: :request do
  let!(:cleanup) { [] }
  after do
    cleanup.each { |r| r.destroy rescue nil }
  end

  describe 'communities#fronttag with a bogus format extension' do
    let!(:community) do
      c = Community.create!(tagname: "crawl#{rand(1e9).to_i}", fullname: 'Crawl Test',
                            front_template: '')
      cleanup << c
      c
    end

    it 'serves the HTML front page for /:tagname' do
      get "/#{community.tagname}"
      expect(response.status).to eq(200)
    end

    it 'does not blow up on /:tagname.zip' do
      expect { get "/#{community.tagname}.zip" }.not_to raise_error
      expect(response.status).to eq(200)
    end

    it 'does not blow up on /:tagname.json' do
      expect { get "/#{community.tagname}.json" }.not_to raise_error
      expect(response.status).to eq(200)
    end
  end

  describe 'conversations#fronttag with a bogus format extension' do
    let!(:conversation) do
      c = Conversation.create!(shortname: "crawlconv#{rand(1e9).to_i}", name: 'Crawl Conv',
                               front_template: '')
      cleanup << c
      c
    end

    it 'does not blow up on /conversation/:tagname.zip' do
      expect { get "/conversation/#{conversation.shortname}.zip" }.not_to raise_error
      expect(response.status).to eq(200)
    end
  end

  describe 'well_known#webfinger with a missing or empty resource' do
    it 'returns 400 when resource is absent' do
      get '/.well-known/webfinger'
      expect(response.status).to eq(400)
    end

    it 'returns 400 for ?resource with no value (nil param)' do
      expect { get '/.well-known/webfinger?resource' }.not_to raise_error
      expect(response.status).to eq(400)
    end

    it 'returns 400 for ?resource= (blank value)' do
      get '/.well-known/webfinger?resource='
      expect(response.status).to eq(400)
    end

    it 'returns 404 for a non-string resource param' do
      expect { get '/.well-known/webfinger?resource[]=acct:x@y.com' }.not_to raise_error
      expect(response.status).to eq(404)
    end

    it 'still rejects a resource that is not an account identifier' do
      get '/.well-known/webfinger?resource=notanaccount'
      expect(response.status).to eq(404)
    end

    it 'still parses a well-formed resource through to the account lookup' do
      get "/.well-known/webfinger?resource=acct:nosuchuser@#{BASEDOMAIN}"
      expect(response.status).to eq(404)
      expect(response.body).to match(/Unknown account/)
    end
  end
end
