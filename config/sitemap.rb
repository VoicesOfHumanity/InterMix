# config/sitemap.rb
return unless Rails.env.production?
SitemapGenerator::Sitemap.default_host = "https://voh.intermix.org"
SitemapGenerator::Sitemap.create do
  # Add main pages
  add root_path, changefreq: 'daily', priority: 1.0

  # # Add conversations
  # Conversation.find_each do |conversation|
  #   add conversation_path(conversation), lastmod: conversation.updated_at, changefreq: 'weekly', priority: 0.8
  # end

  # # Add communities
  # Community.where(is_sub: false).where.not(visibility: "private").find_each do |community|
  #   add community_path(community), lastmod: community.updated_at, changefreq: 'weekly', priority: 0.6
  # end

  # Add posts if needed, though they can be numerous, so use discretion
  Item.find_each do |item|
    add view_item_path(item), lastmod: item.updated_at, changefreq: 'weekly', priority: 0.4
  end
end