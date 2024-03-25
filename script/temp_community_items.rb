require File.dirname(__FILE__)+'/cron_helper'

# Fill in community_items based on tags and fields determining which community an item shows in
# This is to accommodate having one item show up in several communities

# Factors are:
# community tags of the author
# intra_com om item
# representing_com of item

# An item might show in a community where the author is not a member if?
# if a topic was selected, the item would show in the topic's community
# If one responds to an item in a community where one isn't a member?

puts "Create community_items records *****************"

num_added = 0
num_exist = 0
num_com_notfound = 0

items = Item.all

for item in items
    puts "#{item.id} #{item.subject}"
    
    continue if item.posted_by.to_i == 0

    #author = item.participant
    #author_tags = author.tag_list_downcase

    com_tag = ''

    if item.representing_com.to_s != ''
      # a community tag
      com_tag = item.representing_com
    end

    if com_tag == '' and item.intra_com[0] == '@'
      com_tag = item.intra_com[1,50]
    end
    if com_tag == '' and item.visible_com[0] == '@'
      com_tag = item.visible_com[1,50]
    end

    # Suppose we're still showing it, even if the poster wasn't a member
    #item.outside_com_post

    if com_tag != ''
      puts "  com_tag: #{com_tag}"
      com = Community.find_by_tagname(com_tag)
      if com != nil
        com_item = CommunityItem.find_by_item_id_and_community_id(item.id, com.id)
        if com_item == nil
          puts "    creating com_item"
          com_item = CommunityItem.new
          com_item.item_id = item.id
          com_item.community_id = com.id
          com_item.save
          num_added += 1
        else
          puts "    com_item already exists"
          num_exist += 1
        end
        if item.community_id != com.id
          puts "    updating item.community_id"
          item.community_id = com.id
          item.save
        end
      else
        puts "    com not found"
        num_com_notfound += 1
      end
    end


end

puts "Done *****************"

puts "Added #{num_added} community_items"
puts "Existed #{num_exist} community_items"
puts "Community not found: #{num_com_notfound}"