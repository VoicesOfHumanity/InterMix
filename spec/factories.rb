FactoryGirl.define do
  factory :community_admin do
    
  end
  factory :item_subscribe do
    
  end
  factory :community do
    tagname "MyString"
    name "MyString"
  end
  factory :participant do
    email 'ffunch234@newciv.org'
    password 'test'
    password_confirmation 'test'
    confirmed_at = Time.now
    status = 'active'
  end
  factory :group do
    name 'Test Group'
    shortname 'testg'
    openness 'open'
    visibility 'public'
  end
end