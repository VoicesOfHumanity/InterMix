class MoonWinner < ApplicationRecord

  belongs_to :moon, optional: true
  belongs_to :item, optional: true
end
