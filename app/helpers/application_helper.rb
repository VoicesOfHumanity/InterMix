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
  
  def domname(group,dialog)
    #-- Return an appropriate domain name with subdomains, depending on the group and discussion
    if group and group.shortname.to_s != ''
      group_prefix = group.shortname
    else
      group_prefix = ''
    end
    if dialog and dialog.shortname.to_s != ''
      dialog_prefix = dialog.shortname
    else
      dialog_prefix = ''
    end    
    if dialog_prefix != '' and group_prefix != ''
      dom = "#{dialog_prefix}.#{group_prefix}.#{ROOTDOMAIN}"
    elsif group_prefix != ''
      dom = "#{group_prefix}.#{ROOTDOMAIN}"
    elsif dialog_prefix != ''
      dom = "#{dialog_prefix}.#{ROOTDOMAIN}"
    else
      dom = BASEDOMAIN
    end      
    return dom
  end  
  
end
