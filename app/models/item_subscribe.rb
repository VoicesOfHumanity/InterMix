class ItemSubscribe < ActiveRecord::Base
  #belongs_to :item
  #belongs_to :particpant
  belongs_to :subscriber, optional: true, class_name: "Participant", foreign_key: :participant_id
  belongs_to :subscription, optional: true, class_name: "Item", foreign_key: :item_id
end
