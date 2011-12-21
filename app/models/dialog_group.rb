class DialogGroup < ActiveRecord::Base
  belongs_to :dialog
  belongs_to :group
end
