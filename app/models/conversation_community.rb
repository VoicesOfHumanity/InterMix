class ConversationCommunity < ApplicationRecord
  belongs_to :conversation, optional: true
  belongs_to :community, optional: true
end
