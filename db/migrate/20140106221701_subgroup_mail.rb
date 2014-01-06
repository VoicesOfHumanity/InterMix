class SubgroupMail < ActiveRecord::Migration
  def change
    add_column :participants, :subgroup_email, :string, :default => 'instant', :after => :group_email
    add_column :groups, :tweet_subgroups, :boolean, :default => false
  end
end
