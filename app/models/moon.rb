class Moon < ApplicationRecord
  
  has_many :moon_winners

  def previous_date
    # A full moon month before
    previous_moon = Moon.where(new_or_full: self.new_or_full).where("mdate<'#{self.mdate}'").order("mdate desc").first
    previous_moon.mdate
  end

  def previous_date_half
    # A half moon month before
    previous_moon = Moon.where("mdate<'#{self.mdate}'").order("mdate desc").first
    previous_moon.mdate
  end

  def next_date
    next_moon = Moon.where(new_or_full: self.new_or_full).where("mdate>'#{self.mdate}'").order(:mdate).first
    next_moon.mdate
  end
  
  
end
