#-- period_results.rb ---- Calculate top results for each discussion period

require File.dirname(__FILE__)+'/cron_helper'

@metamaps = Metamap.where(:id=>[3,5])

periods = Period.where(nil)

for period in periods
  
  next if not period.dialog
  
  puts "Period:#{period.id} #{period.period_number.to_i > 0 ? "##{period.period_number} " : ""}#{period.startdate} Name:#{period.name} Discussion:#{period.dialog_id}:#{period.dialog.name}"

  @data = {}
  result = {}
  
  #-- Overall results
  items, itemsproc, extras = Item.list_and_results(nil,period.dialog,period.id,0,{},{},true,'*value*',nil,true,0,'','','','','','','','','','',true)
  @data['totals'] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
  
  puts "  #{items.size} items"

if false  
  if items.size > 0
    win = items[0]
    puts "  winner: #{win.participant.name}: #{win.subject}"
    result['totals'] = {'item'=>items[0],'iproc'=>itemsproc[items[0].id]}  
  else
    puts "  no results"
  end  
end

  #-- And meta category results
  @data['meta'] = extras['meta'] 
  if period.crosstalk[0..5] == 'gender' or period.crosstalk[0..2] == 'age'
    for metamap in @metamaps
      if period.crosstalk[0..5] == 'gender' and metamap.id == 3
      elsif period.crosstalk[0..2] == 'age' and metamap.id == 5
      else
        next
      end  
      puts "  meta:##{metamap.id}:#{metamap.name}"
      result[period.crosstalk] = []
    
      puts @data['meta'][metamap.id]['nodes_sorted'].inspect
      for metamap_node_id,minfo in @data['meta'][metamap.id]['nodes_sorted']
    		metamap_node_name = minfo[0]
    		metamap_node = minfo[1]
    		if  @data['meta'][metamap.id]['postedby']['nodes'][metamap_node_id] and  @data['meta'][metamap.id]['postedby']['nodes'][metamap_node_id]['items'].length > 0
    			if @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id].length > 0
      			for rate_metamap_node_id,rdata in @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id]
      			  if rate_metamap_node_id == metamap_node_id
    	          item_id,i = @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id][rate_metamap_node_id]['itemsproc'][0]
    	          item = Item.find_by_id(item_id)
    	          puts "    #{metamap_node_name}: #{item.participant.name}: #{item.subject}"
    	          #result[period.crosstalk] << {'item'=>item,'iproc'=>itemsproc[item.id],'label'=>metamap_node_name}
                
                useitem = item.attributes
                
                useitem['subgroup_list'] = item.subgroup_list
                useitem['show_subgroup'] = item.show_subgroup
                useitem['tag_list'] = item.tag_list
                useitem['item_rating_summary'] = item.item_rating_summary
                
                useitem['participant'] = item.participant ? item.participant.attributes : nil
                useitem['dialog'] = item.dialog ? item.dialog.attributes : nil
                useitem['group'] = item.group ? item.group.attributes : nil
                useitem['period'] = item.period ? item.period.attributes : nil
                
                useitem['participant']['name'] = item.participant.name if item.participant
                useitem['dialog']['settings_with_period'] = item.dialog.settings_with_period if item.dialog
                
                
                iproc = itemsproc[item.id]
                useiproc = []
                
                result[period.crosstalk] << {'item'=>useitem,'iproc'=>useiproc,'label'=>metamap_node_name}                
                
    	        end
    	      end
    	    end
        end
      end  
    
    end   
  end
  
if false  
  #-- Results per group
  @data['groups'] = {}
  result['groups'] = {}
  if period.dialog.groups.size > 0
    #-- Stats by group
    for group in period.dialog.groups
      #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
      items, itemsproc, extras = Item.list_and_results(group,period.dialog,period.id,0,{},{},true,'*value*',nil,true,0,'','','','','','','','','','')        
      @data['groups'][group.id] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
      puts "  Group:#{group.name}"
      if items.size > 0
        win = items[0]
        puts "    winner: #{win.participant.name}: #{win.subject}"
        result['groups'][group.id] = {'item'=>items[0],'iproc'=>itemsproc[items[0].id],'label'=>group.name}  
      else
        puts "    no results"
      end  
    end
  end  
end

  #puts result.inspect
  period.result_will_change!
  period.result = result
  period.save!
  
end

