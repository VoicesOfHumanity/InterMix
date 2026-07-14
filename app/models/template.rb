class Template < ActiveRecord::Base
  belongs_to :group, optional: true
end
