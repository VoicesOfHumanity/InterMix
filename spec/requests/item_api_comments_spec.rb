# items#item_api put the PARENT's html_content on every comment hash, and gave
# comments no 'link' key (list_api did), so a reply's picture vanished once the
# mobile app refetched the detail view. Reported by the Voices of Humanity app,
# 2026-09-14. list_api had the same html_content mistake, fixed in the same commit;
# it is not exercised here because it needs the whole listing filter pipeline.
#
# NOTE: items/participants are MyISAM and do not roll back, so clean up explicitly.
require 'rails_helper'

RSpec.describe 'items#item_api comments', type: :request do
  let!(:cleanup) { [] }
  after { cleanup.reverse.each { |r| r.destroy rescue nil } }

  let!(:author) do
    p = Participant.create!(first_name: 'API', last_name: 'Tester',
                            email: "itemapi_#{rand(1e12).to_i}@example.com", password: 'password1')
    cleanup << p
    p
  end

  # The app always calls item_api signed in (auth_token). Anonymously, item_api
  # 500s on current_participant.id further down -- a separate, older bug.
  # login_as is a one-shot for the next request; each example makes exactly one.
  before { login_as(author, scope: :participant) }
  after  { Warden.test_reset! }

  let!(:parent) do
    i = Item.create!(subject: 'parent', html_content: '<p>parent body</p>',
                     posted_by: author.id, is_first_in_thread: true)
    cleanup << i
    i
  end

  def make_reply(html:, has_picture: false)
    r = Item.create!(subject: 'reply', html_content: html, posted_by: author.id,
                     is_first_in_thread: false, first_in_thread: parent.id,
                     reply_to: parent.id, has_picture: has_picture)
    cleanup << r
    r
  end

  def comments
    get "/items/#{parent.id}/item_api"
    expect(response.status).to eq(200)
    JSON.parse(response.body)['comments']
  end

  it "gives each comment its own html_content, not the parent's" do
    reply = make_reply(html: '<p>reply body <img src="https://example.com/x.jpg"></p>')
    com = comments.find { |c| c['id'] == reply.id }
    expect(com['html_content']).to eq(reply.html_content)
  end

  it "gives a comment with a picture the same big.jpg link list_api does" do
    reply = make_reply(html: '<p>with picture</p>', has_picture: true)
    com = comments.find { |c| c['id'] == reply.id }
    expect(com['link']).to eq("https://#{BASEDOMAIN}/images/data/items/#{reply.id}/big.jpg")
  end

  it "gives a comment without a picture an empty link" do
    reply = make_reply(html: '<p>no picture</p>')
    com = comments.find { |c| c['id'] == reply.id }
    expect(com['link']).to eq('')
  end
end
