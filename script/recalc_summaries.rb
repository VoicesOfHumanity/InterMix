# encoding: utf-8

# Recalculate all item summaries

require File.dirname(__FILE__)+'/cron_helper'

irs = ItemRatingSummary.all

for ir in irs
  print "#{ir.item_id}\n"
  
  item = Item.includes(:dialog,:group).find_by_id(ir.item_id)
  if item
    @dialog = item.dialog
    @group = item.group
    ir.recalculate(false,@dialog)

    item.interest = ir.int_average
    item.approval = ir.app_average
    item.save

  end
end