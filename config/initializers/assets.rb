# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0.2'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# not included everywhere, but specifically linked to:
Rails.application.config.assets.precompile += %w( admin.css formtastic.css formtastic_changes.css pepper-grinder/jquery-ui-1.8.6.custom.css blueprint/print.css blueprint/ie.css ckeditor/config.js )
