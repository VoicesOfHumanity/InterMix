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

  describe '.activity_counts (batched)' do
    def count_queries
      n = 0
      sub = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        n += 1 unless payload[:name].to_s =~ /SCHEMA|TRANSACTION/
      end
      yield
      n
    ensure
      ActiveSupport::Notifications.unsubscribe(sub)
    end

    it 'returns a 0-defaulting hash keyed by downcased tagname' do
      counts = Community.activity_counts([tag])
      expect(counts[tag.downcase]).to eq(0)
      expect(counts['nobody-uses-this-tag']).to eq(0)
    end

    it 'handles no tagnames without touching the database' do
      expect(Community.activity_counts([])).to eq({})
      expect(Community.activity_counts(nil)['anything']).to eq(0)
    end

    it 'counts several communities correctly in one pass' do
      make_item(author: make_participant(tagged: true), tagged: true)   # 1 for `tag`

      other_tag = "actag#{rand(1e12).to_i}"
      other = Community.create!(tagname: other_tag, fullname: 'Other')
      cleanup << other
      other_author = Participant.create!(first_name: 'AC', last_name: 'Other',
                                         email: "aco_#{rand(1e12).to_i}@example.com",
                                         password: 'password1')
      other_author.tag_list.add(other_tag)
      other_author.save!
      cleanup << other_author
      2.times do
        i = Item.create!(subject: 'other', html_content: 'b',
                         posted_by: other_author.id, created_at: 1.day.ago)
        i.tag_list.add(other_tag)
        i.save!
        cleanup << i
      end

      counts = Community.activity_counts([tag, other_tag])
      expect(counts[tag.downcase]).to eq(1)
      expect(counts[other_tag.downcase]).to eq(2)
    end

    it 'matches tagnames case-insensitively, like tagged_with does' do
      make_item(author: make_participant(tagged: true), tagged: true)
      expect(Community.activity_counts([tag.upcase])[tag.downcase]).to eq(1)
    end

    it 'agrees with the per-community activity_count' do
      make_item(author: make_participant(tagged: true), tagged: true)
      expect(Community.activity_counts([tag])[tag.downcase]).to eq(community.activity_count)
    end

    it 'uses a single query regardless of how many communities are asked for' do
      make_item(author: make_participant(tagged: true), tagged: true)
      many = ([tag] * 3) + 40.times.map { |i| "nosuchtag#{i}" }
      queries = count_queries { Community.activity_counts(many) }
      expect(queries).to eq(1)
    end
  end
end
