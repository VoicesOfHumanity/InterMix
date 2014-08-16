#-- period_results.rb ---- Calculate top results for each discussion period

require File.dirname(__FILE__)+'/cron_helper'

periods = Period.all

for period in periods

  @data = {}
  
  #-- Overall results
  items, itemsproc, extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,{},{},true,@sortby,current_participant,true,0,'','','','','','','','','','',true)
  @data['totals'] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
  
  #-- And meta category results
  @data['meta'] = extras['meta']
  
  
  #-- Results per group
  @data['groups'] = {}
  if @limit_group_id == 0
    #-- Stats by group
    for group in @dialog.groups
      #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
      items, itemsproc, extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','','','','','','','','','')        
      @data['groups'][group.id] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
    end
  end
  
  
  
  
end
