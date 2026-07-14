class DialogAdmin < ActiveRecord::Base
  belongs_to :dialog, optional: true
  belongs_to :participant, optional: true
end
