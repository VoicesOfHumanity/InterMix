module ApplicationHelper
  
  def is_approval? (item, num)
    #-- Answer whether the current item has been rated by the current user with a certain approval rating
    #-- The user's rating is exected to be in item.approval if there is one
    if item and item.has_key?('hasrating') and item['hasrating'] and item['rateapproval'] and item['rateapproval'].to_i == num
      true
    else
      false
    end    
  end
  
  def is_interest? (item, num)
    #-- Answer whether the current item has been rated by the current user with a certain interest rating
    #-- The user's rating is exected to be in item.interest if there is one
    if item and item.has_key?('hasrating') and item['hasrating'] and item['rateinterest'] and item['rateinterest'].to_i == num
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
  
  def link_to_function(name, function, html_options={})
    #message = "link_to_function is deprecated and will be removed from Rails 4.1. We recommend using Unobtrusive JavaScript instead. " +
    "See http://guides.rubyonrails.org/working_with_javascript_in_rails.html#unobtrusive-javascript"
    #ActiveSupport::Deprecation.warn message

    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    href = html_options[:href] || '#'

    content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
  end
  
  def button_to_function(name, function=nil, html_options={})
    #message = "button_to_function is deprecated and will be removed from Rails 4.1. We recommend using Unobtrusive JavaScript instead. " +
    "See http://guides.rubyonrails.org/working_with_javascript_in_rails.html#unobtrusive-javascript"
    #ActiveSupport::Deprecation.warn message

    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function};"

    tag(:input, html_options.merge(:type => 'button', :value => name, :onclick => onclick))
  end
        
end
