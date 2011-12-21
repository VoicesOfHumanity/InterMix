module ApplicationHelper
  
  def is_approval? (item, num)
    #-- Answer whether the current item has been rated by the current user with a certain approval rating
    #-- The user's rating is exected to be in item.approval if there is one
    if item['hasrating'] and item['rateapproval'].to_i == num
      true
    else
      false
    end    
  end
  
  def is_interest? (item, num)
    #-- Answer whether the current item has been rated by the current user with a certain interest rating
    #-- The user's rating is exected to be in item.interest if there is one
    if item['hasrating'] and item['rateinterest'].to_i == num
      true
    else
      false
    end    
  end
  
end
