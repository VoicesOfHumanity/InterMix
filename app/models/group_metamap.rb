class GroupMetamap < ActiveRecord::Base
  belongs_to :group, optional: true
  belongs_to :metamap, optional: true
end
