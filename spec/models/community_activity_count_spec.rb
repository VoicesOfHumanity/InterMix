# Characterization spec for Community#activity_count, written BEFORE refactoring it.
# It must pass against the original implementation, so it can prove the rewrite
# preserves behaviour rather than just documenting whatever the rewrite happens to do.
#
# Semantics being pinned: count items from the last 31 days that are BOTH tagged with
# the community's tagname AND authored by a participant tagged with that same tagname.
#
# NOTE: items/participants/taggings are MyISAM and do not roll back, so every record is
# cleaned up explicitly.
require 'rails_helper'

RSpec.describe Community, '#activity_count' do
  let!(:cleanup) { [] }
  after { cleanup.reverse.each { |r| r.destroy rescue nil } }

  let(:tag) { "actag#{rand(1e12).to_i}" }

  let!(:community) do
    c = Community.create!(tagname: tag, fullname: 'Activity Count Test')
    cleanup << c
    c
  end

  def make_participant(tagged:)
    p = Participant.create!(first_name: 'AC', last_name: 'User',
                            email: "ac_#{rand(1e12).to_i}@example.com", password: 'password1')
    if tagged
      p.tag_list.add(tag)
      p.save!
    end
    cleanup << p
    p
  end

  def make_item(author:, tagged:, created_at: 2.days.ago)
    i = Item.create!(subject: 'ac item', html_content: 'body',
                     posted_by: author.id, created_at: created_at)
    if tagged
      i.tag_list.add(tag)
      i.save!
    end
    cleanup << i
    i
  end

  it 'is 0 when nothing is tagged' do
    expect(community.activity_count).to eq(0)
  end

  it 'counts a recent tagged item by a tagged participant' do
    make_item(author: make_participant(tagged: true), tagged: true)
    expect(community.activity_count).to eq(1)
  end

  it 'counts several such items' do
    author = make_participant(tagged: true)
    3.times { make_item(author: author, tagged: true) }
    expect(community.activity_count).to eq(3)
  end

  it 'excludes items older than 31 days' do
    author = make_participant(tagged: true)
    make_item(author: author, tagged: true, created_at: 60.days.ago)
    expect(community.activity_count).to eq(0)
  end

  it 'excludes items whose author is not tagged with the community' do
    make_item(author: make_participant(tagged: false), tagged: true)
    expect(community.activity_count).to eq(0)
  end

  it 'excludes items that are not tagged, even from a tagged author' do
    make_item(author: make_participant(tagged: true), tagged: false)
    expect(community.activity_count).to eq(0)
  end

  it 'counts only the qualifying items in a mixed set' do
    tagged_author   = make_participant(tagged: true)
    untagged_author = make_participant(tagged: false)
    make_item(author: tagged_author,   tagged: true)                            # counts
    make_item(author: tagged_author,   tagged: true)                            # counts
    make_item(author: tagged_author,   tagged: true, created_at: 90.days.ago)   # too old
    make_item(author: tagged_author,   tagged: false)                           # untagged item
    make_item(author: untagged_author, tagged: true)                            # untagged author
    expect(community.activity_count).to eq(2)
  end

  it 'is 0 for a community whose tagname nobody uses' do
    other = Community.create!(tagname: "unused#{rand(1e12).to_i}", fullname: 'Unused')
    cleanup << other
    make_item(author: make_participant(tagged: true), tagged: true)
    expect(other.activity_count).to eq(0)
  end
end
