class ItemRatingSummary < ActiveRecord::Base
  belongs_to :item
  
  def recalculate(explain=false,dialog=nil)
    #-- Add up all the numbers for a ratings summary record
    
    zero
    
    self.summary_type = 'AllRatings' if not summary_type
    
    ratings = Rating.where("item_id=#{item_id}")
    puts "#{ratings.length} ratings" if explain
    for rating in ratings
      if rating.interest
        self.int_count += 1
        case rating.interest
        when 0
          self.int_0_count += 1
        when 1
          self.int_1_count += 1
          self.int_total += 1
        when 2
          self.int_2_count += 1
          self.int_total += 2
        when 3
          self.int_3_count += 1
          self.int_total += 3
        when 4
          self.int_4_count += 1
          self.int_total += 4
        end        
      end  
      if rating.approval
        self.app_count += 1
        case rating.approval
        when -3
          self.app_n3_count +=1   
          self.app_total -= 3
        when -2
          self.app_n2_count +=1   
          self.app_total -= 2
        when -1
          self.app_n1_count +=1   
          self.app_total -= 1
        when 0
          self.app_0_count +=1   
        when 1
          self.app_p1_count +=1   
          self.app_total += 1
        when 2
          self.app_p2_count +=1   
          self.app_total += 2
        when 3
          self.app_p3_count +=1   
          self.app_total += 3
        end  
      end        
    end  
    puts "int totals: 0:#{self.int_0_count} 1:#{self.int_1_count} 2:#{self.int_2_count} 3:#{self.int_3_count} 4:#{self.int_4_count} total:#{self.int_count}/#{self.int_total}" if explain
    puts "app totals: -3:#{self.app_n3_count} -2:#{self.app_n2_count} -1:#{self.app_n1_count} 0:#{self.app_0_count} +1:#{self.app_p1_count} +2:#{self.app_p2_count} +3:#{self.app_p3_count} total:#{self.app_count}/#{app_total}" if explain
    
    xint_average = int_count > 0 ? (1.0 * int_total / int_count) : 0.0
    xapp_average = app_count > 0 ? (1.0 * app_total / app_count) : 0.0
    
    puts "calculated averages: int:#{xint_average} app:#{xapp_average}" if explain
    
    self.int_average = xint_average
    self.app_average = xapp_average

    puts "stored averages: int:#{self.int_average} app:#{self.app_average}" if explain
    
    #logger.info("item_rating_summary#recalculate item:#{self.item_id} dialog:#{dialog.id} value_calc:#{dialog.value_calc}")
    
    if dialog and dialog.value_calc == 'avg'
      self.value = xint_average * xapp_average
      puts "value, #{xint_average}(int_average) * #{xapp_average}(app_average) = #{self.value}" if explain
    else
      self.value = self.int_count * xapp_average
      puts "value, #{self.int_count}(int_count) * #{xapp_average}(app_average) = #{self.value}" if explain
    end
    
    if self.app_count > 0
      xcontroversy = (1.0 * ( self.app_n3_count * (-3.0 - xapp_average)**2 + self.app_n2_count * (-2.0 - xapp_average)**2 + self.app_n1_count * (-1.0 - xapp_average)**2 + self.app_0_count * (0.0 - xapp_average)**2 + self.app_p1_count * (1.0 - xapp_average)**2 + self.app_p2_count * (2.0 - xapp_average)**2 + self.app_p3_count * (3.0 - xapp_average)**2 ) / self.app_count)
      puts "controversy: 1.0 * (#{self.app_n3_count} * (-3.0 - #{xapp_average})**2 + #{self.app_n2_count} * (-2.0 - #{xapp_average})**2 + #{self.app_n1_count} * (-1.0 - #{xapp_average})**2 + #{self.app_0_count} * (0.0 - #{xapp_average})**2 + #{self.app_p1_count} * (1.0 - #{xapp_average})**2 + #{self.app_p2_count} * (2.0 - #{xapp_average})**2 + #{self.app_p3_count} * (3.0 - #{xapp_average})**2 ) / #{self.app_count} = #{xcontroversy}" if explain
      self.controversy = xcontroversy
      puts "controversy stored: #{self.controversy}" if explain
    else
      puts "controversy is 0.00 because app_count is zero" if explain    
    end
    
    self.save!  
    
  end
  
  def sumupdate(intapp, vote)
    #-- Add one vote to the results
    self.summary_type = 'AllRatings' if not summary_type
    
    if intapp == 'int'
      self.int_count += 1
      case vote
      when 0
        self.int_0_count += 1
      when 1
        self.int_1_count += 1
        self.int_total += 1
      when 2
        self.int_2_count += 1
        self.int_total += 2
      when 3
        self.int_3_count += 1
        self.int_total += 3
      when 4
        self.int_4_count += 1
        self.int_total += 4
      end        
    end  
    if intapp == 'app'
      self.app_count += 1
      case vote
      when -3
        self.app_n3_count +=1   
        self.app_total -= 3
      when -2
        self.app_n2_count +=1   
        self.app_total -= 2
      when -1
        self.app_n1_count +=1   
        self.app_total -= 1
      when 0
        self.app_0_count +=1   
      when 1
        self.app_p1_count +=1   
        self.app_total += 1
      when 2
        self.app_p2_count +=1   
        self.app_total += 2
      when 3
        self.app_p3_count +=1   
        self.app_total += 3
      end  
    end        

    self.int_average = self.int_count > 0 ? self.int_total / self.int_count : 0
    self.app_average = self.app_count > 0 ? self.app_total / self.app_count : 0
    
    self.value = self.int_count * self.app_average
    
    self.controversy = 0
    if app_count > 0
      self.controversy = ( self.app_n3_count * (-3 - self.app_average)**2
        + self.app_n2_count * (-2 - self.app_average)**2
        + self.app_n1_count * (-1 - self.app_average)**2
        + self.app_0_count * (0 - self.app_average)**2
        + self.app_p1_count * (1 - self.app_average)**2
        + self.app_p2_count * (2 - self.app_average)**2
        + self.app_p3_count * (3 - self.app_average)**2 ) / self.app_count
    end 
    
    self.save! 
    
  end  
  
  def zero
    self.int_0_count = 0
    self.int_1_count = 0
    self.int_2_count = 0
    self.int_3_count = 0
    self.int_4_count = 0
    self.int_count = 0
    self.int_total = 0
    self.int_average= 0.0
    self.app_n3_count = 0
    self.app_n2_count = 0
    self.app_n1_count = 0
    self.app_0_count = 0
    self.app_p1_count = 0
    self.app_p2_count = 0
    self.app_p3_count = 0
    self.app_count = 0
    self.app_total = 0
    self.app_average= 0.0
    self.value = 0.0
    self.controversy = 0.0
  end  
    
end
