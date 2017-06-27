module ApplicationHelper
  
  def clean_links(oldhtml)
    #-- Assume we're getting an item full html, possibly with some embedded images. 
    #-- Turn http into https if they're our own. If foreign http hot links, remove them.
    newhtml = oldhtml
    
    #voh.intermix
    #intermix
    
    # <img alt="" src="http://intermix.dev:3002/ckeditor_assets/pictures/14/content_jjetu1x.jpg" style="height:218px; width:300px">
    
    newhtml.gsub!(/http:\/\/intermix\./im,'//intermix.')
    newhtml.gsub!(/http:\/\/voh\.intermix\./im,'//voh.intermix.')
        
    return newhtml
  end
  
  def is_approval? (item, num)
    #-- Answer whether the current item has been rated by the current user with a certain approval rating
    #-- The user's rating is exected to be in item.approval if there is one
    if item and item.has_key?('hasrating') and item['hasrating'].to_i > 0 and item['rateapproval'].class == Fixnum and item['rateapproval'] == num
      true
    else
      false
    end    
  end
  
  def is_interest? (item, num)
    #-- Answer whether the current item has been rated by the current user with a certain interest rating
    #-- The user's rating is exected to be in item.interest if there is one
    if item and item.has_key?('hasrating') and item['hasrating'].to_i > 0 and item['rateinterest'].class == Fixnum and item['rateinterest'] == num
      true
    else
      false
    end    
  end
  
  def thumbvote(iproc)
    # Show the thumbs up/down pictures under an item
    return '' if not iproc or not iproc.has_key?('id')
    item_id = iproc['id']
    value = Item.thumbs(iproc)
    out = ''
    #out += "value:#{value} "
    #out += "rateapproval:#{iproc['rateapproval']} "
    #out += "iproc:#{iproc.inspect} "
    for num in [-3,-2,-1,0,1,2,3]
      style = ''
      if num == 0
        #out += "&nbsp;\n"
      else
        onoff = ''
        showing = 0
        if num < 0
          onoff = (value <= num or (value != 0  and num == value - 1)) ? 'on' : 'off'          
          imgsrc = "/images/thumbsdown#{onoff}.jpg"
          domid = "thumb_#{item_id}_down_#{num.abs}"
          if num < -1 and value > num + 1
            style = "opacity:0"
          else
            showing = 1  
            if onoff == 'off' or num < value
              style = "opacity:0.5"
            end
          end
        else
          onoff = (value >= num or (value != 0 and num == value + 1)) ? 'on' : 'off'
          imgsrc = "/images/thumbsup#{onoff}.jpg"
          domid = "thumb_#{item_id}_up_#{num.abs}"
          if num > 1 and value < num - 1
            style = "opacity:0"
          else
            showing = 1
            if onoff == 'off' or num > value
              style = "opacity:0.5"
            end
          end      
        end
        out += "<a href=\"#\" onclick=\"clickthumb(#{item_id},#{num});return(false)\"><img src=\"#{imgsrc}\" id=\"#{domid}\" style=\"#{style}\" class=\"thumbupdown\" data-item-id=\"#{item_id}\" data-num=\"#{num}\" data-value=\"#{Item.thumbs(iproc)}\" data-onoff=\"#{onoff}\" data-showing=\"#{showing}\"></a>\n"
      end
    end
    out
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
  
  def julian(year, month, day)
    a = (14-month)/12
    y = year+4800-a
    m = (12*a)-3+month
    return day + (153*m+2)/5 + (365*y) + y/4 - y/100 + y/400 - 32045
  end
  
  def moonphase(year,month,day)
    p=(julian(year,month,day)-julian(2000,1,6))%29.530588853
    if p<1.84566
      return "New"
    elsif p<5.53699
      return "Waxing crescent"
    elsif p<9.22831
      return "First quarter"
    elsif p<12.91963
      return "Waxing gibbous"
    elsif p<16.61096
      return "Full"
    elsif p<20.30228
      return "Waning gibbous"
    elsif p<23.99361
      return "Last quarter"
    elsif p<27.68493
      return "Waning crescent"
    else
      return "New"
    end
  end
  
  #print "#{phase(2020,1,23)}\n"
  #print "#{phase(1999,1,6)}\n"
  #print "#{phase(2010,2,10)}\n"
  #print "#{phase(1987,5,10)}\n"
        
end
