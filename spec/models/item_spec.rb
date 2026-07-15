require 'rails_helper'

RSpec.describe Item, type: :model do
  describe '#subject_or_excerpt' do
    # Regression: an item with no subject AND empty/whitespace-only content
    # made `excerpt` return "", so `"".split.first` was nil and `nil[0]`
    # raised `undefined method [] for nil:NilClass` (items#view, item.rb:63).
    it 'returns "" when there is no subject and the content is blank' do
      expect(Item.new(subject: '', html_content: '   ').subject_or_excerpt).to eq('')
    end

    it 'returns "" when content sanitizes to empty (tags only)' do
      expect(Item.new(subject: nil, html_content: '<p></p>').subject_or_excerpt).to eq('')
    end

    it 'strips a leading @mention from the excerpt' do
      expect(Item.new(subject: '', html_content: '@alice hello there').subject_or_excerpt)
        .to eq('hello there')
    end

    it 'falls back to the excerpt when there is no subject' do
      expect(Item.new(subject: '', html_content: 'just some words').subject_or_excerpt)
        .to eq('just some words')
    end

    it 'returns the subject when present' do
      expect(Item.new(subject: 'My Subject', html_content: 'x').subject_or_excerpt)
        .to eq('My Subject')
    end
  end
end
