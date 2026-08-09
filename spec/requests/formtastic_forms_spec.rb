# Regression coverage for a production 500 in communities#new (2026-08):
#   ActionView::Template::Error: undefined method `silence' for
#   ActiveSupport::Deprecation:Class    (app/views/communities/edit.html.erb:14)
# Formtastic 4.0 wrapped every column_for_attribute lookup in
# ActiveSupport::Deprecation.silence, which Rails 7.1 turned into an instance
# method — so every f.input against an AR object raised. Formtastic 6.0 uses its
# own deprecator. This guards the whole semantic_form_for surface, not just the
# one page that got reported.
# NOTE: participants are MyISAM and do not roll back, so clean up explicitly.
require 'rails_helper'

RSpec.describe 'Formtastic forms render', type: :request do
  let!(:cleanup) { [] }

  let!(:participant) do
    p = Participant.new(email: "ftastic#{rand(1e9).to_i}@example.com",
                        password: 'testtest', password_confirmation: 'testtest')
    p.save!
    p.update_columns(status: 'active', confirmed_at: Time.now)
    cleanup << p
    p
  end

  before { login_as(participant, scope: :participant) }

  #-- NOTE: these render with no standing-conversation rows at all. The "front"
  #-- layout used to call .active straight off Conversation.find_by_id(
  #-- INT_CONVERSATION_ID) with no nil guard, unlike its six neighbours, so a
  #-- missing or renumbered Nations row 500'd every page on that layout.

  after do
    Warden.test_reset!
    cleanup.each { |r| r.destroy rescue nil }
  end

  it 'renders the new community form' do
    expect { get '/communities/new' }.not_to raise_error
    expect(response.status).to eq(200)
    expect(response.body).to include('name="community[tagname]"')
  end

  it 'renders the profile edit form' do
    expect { get '/me/profile/edit' }.not_to raise_error
    expect(response.status).to eq(200)
  end

  # Direct cover for the input types the app's semantic_form_for views use, so a
  # future formtastic bump that breaks one of them fails here rather than in
  # production.
  describe 'every input type used in app/views' do
    let(:view) do
      lookup = ActionView::LookupContext.new(ActionController::Base.view_paths)
      ActionView::Base.with_empty_template_cache.new(lookup, {}, ActionController::Base.new)
    end

    {
      string:   { as: :string },
      text:     { as: :text },
      hidden:   { as: :hidden },
      password: { as: :password },
      select:   { as: :select, collection: { 'Never' => 'never' }, include_blank: false },
      radio:    { as: :radio, collection: { 'Never' => 'never' } },
      boolean:  { as: :boolean },
      file:     { as: :file },
    }.each do |name, opts|
      it "renders an #{name} input" do
        attribute = opts[:as] == :boolean ? :sysadmin : :forum_email
        html = nil
        expect {
          html = view.semantic_form_for(Participant.new, url: '/x') do |f|
            f.inputs { f.input(attribute, **opts) }
          end
        }.not_to raise_error
        expect(html.to_s).to include('<form')
      end
    end
  end
end
