class DialogMetamap < ActiveRecord::Base
  belongs_to :dialog, optional: true
  belongs_to :metamap, optional: true
end
