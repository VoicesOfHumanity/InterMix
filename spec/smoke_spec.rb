# Smoke / boot safety net — the baseline to run before and after each step of the
# Rails 5.2 -> 6.0 -> 6.1 -> Ruby 3.1 -> 7.0 upgrade (AUDIT.md §3). If a framework
# bump removes an API, breaks autoloading, or drops a route, these fail fast.
require 'rails_helper'

RSpec.describe 'Application smoke (upgrade safety net)' do
  it 'eager-loads every application file without error' do
    # The highest-value upgrade check: loads all app/ code in one shot, so a
    # removed constant / changed API / bad require surfaces here rather than in
    # a random production request.
    expect { Rails.application.eager_load! }.not_to raise_error
  end

  it 'loads the full route set' do
    expect(Rails.application.routes.routes.size).to be > 100
  end

  it 'resolves the key named/AP routes' do
    routes = Rails.application.routes
    expect(routes.recognize_path('/nodeinfo/2.0')).to include(controller: 'well_known')
    expect(routes.recognize_path('/api/login')).to include(controller: 'api', action: 'login')
  end

  it 'core models are queryable (schema + AR still line up)' do
    expect {
      [Item, Participant, Community, Dialog, Conversation, Group, Rating,
       RemoteActor, Follow, ApiRequest, ApiSend].each { |m| m.limit(1).to_a }
    }.not_to raise_error
  end

  it 'core model associations the app relies on still resolve' do
    # Guards the associations that _item / the AP code dereference.
    expect { Item.new.dialog; Item.new.conversation; Item.new.orig_item; Item.new.participant }.not_to raise_error
    expect { Participant.new.activitypub_url }.not_to raise_error
  end
end
