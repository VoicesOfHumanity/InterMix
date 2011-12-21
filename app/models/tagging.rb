class Tagging < ActiveRecord::Base

  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  def self.tags_for(type,fname='showbytag')
    uniqtags = self.find_by_sql("select distinct(tag_id),tags.name from taggings,tags where taggable_type='#{type}' and taggings.tag_id=tags.id")
    txt = ""
    for uniqtag in uniqtags
      tag_id = uniqtag.tag_id
      tagname = uniqtag.name
      txt += %(<a href="javascript:#{fname}(#{tag_id},'#{tagname}')">#{tagname}</a>, )
    end  
    txt
  end
end
