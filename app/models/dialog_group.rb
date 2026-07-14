class DialogGroup < ActiveRecord::Base
  belongs_to :dialog, optional: true
  belongs_to :group, optional: true
end
