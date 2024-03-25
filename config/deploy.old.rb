#require 'bundler/capistrano'

towhich = 'live'  # live or staging

#$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
#require "rvm/capistrano"                  # Load RVM's capistrano plugin.
if towhich == 'live'
  #set :rvm_ruby_string, '1.9.3'
  #set :default_environment, {
  #  'PATH' => "/usr/local/rvm/gems/ruby-1.9.3-p392@global/bin:$PATH",
  #  'RUBY_VERSION' => 'ruby 1.9.3',
  #  'GEM_HOME'     => '/usr/local/rvm/gems/ruby-1.9.3-p392@global',
  #  'GEM_PATH'     => '/usr/local/rvm/gems/ruby-1.9.3-p392@global',
  #  'BUNDLE_PATH'  => '/usr/local/rvm/gems/ruby-1.9.3-p392@global'  # If you are using bundler.
  #}
  set :branch, "production"
else
  #set :default_environment, {
  #  'RUBY_VERSION' => 'ruby 2.1.1',
  #  'GEM_HOME'     => '/usr/local/lib/ruby/gems/2.1.0/gems',
  #  'GEM_PATH'     => '/usr/local/lib/ruby/gems/2.1.0/gems',
  #  'BUNDLE_PATH'  => '/usr/local/lib/ruby/gems/2.1.0/gems'  # If you are using bundler.
  #}  
  set :branch, "master"
end

#set :rvm_type, :system        # Default is now :user
set :rake, "bundle exec rake"

load 'deploy/assets'

set :application, "Intermix"
#set :repository, "git@github.com:VoicesOfHumanity/InterMix.git"
set :repository, "http://github.com/VoicesOfHumanity/InterMix.git"
set :repository, "https://github.com/VoicesOfHumanity/InterMix.git"
#set :local_repository, "ploy@sirius.cr8.com:/home/git/intermix"
set :user, 'ploy'
set :password, 'eu4bd8%t'
set :ssh_options, { :user => "ploy", :port => 22, :forward_agent => true }
set :scm, :git
set :scm_username, 'ploy'
set :scm_password, 'eu4bd8%t'
set :runner, 'ploy'
set :keep_releases, 10
set :deploy_via, :checkout
set :git_shallow_clone, 1
#set :branch, "master"
set :use_sudo, false
set :deploy_to, "/home/apps/intermix"
default_run_options[:pty] = true

if towhich == 'live'
  role :web, "server.intermix.org"                          # Your HTTP server, Apache/etc
  role :app, "server.intermix.org"                          # This may be the same as your `Web` server
  role :db,  "server.intermix.org", :primary => true # This is where Rails migrations will run
else
  role :web, "sirius.cr8.com"                          # Your HTTP server, Apache/etc
  role :app, "sirius.cr8.com"                          # This may be the same as your `Web` server
  role :db,  "sirius.cr8.com", :primary => true # This is where Rails migrations will run
end
#role :db,  "your slave db-server here"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end  
end

task :bundle_install, :roles => :app do
    #run "/bin/cp -a #{release_path} /home/apps/intermix/releases/temp"
    run "cd #{release_path} && bundle install"
end
task :data_symlinks do
  run "ln -s /home/apps/intermix/shared/data #{release_path}/public/images/data"
end
task :config_symlinks do
  #run "ln -s /home/apps/intermix/shared/config/database.yml #{release_path}/config/database.yml"
  run "ln -sf /home/apps/intermix/shared/config/database.yml #{latest_release}/config/database.yml"
  run "ln -sf /home/apps/intermix/shared/config/localsettings.rb #{release_path}/config/localsettings.rb"
  run "/bin/cp /home/apps/intermix/ruby-version #{release_path}/.ruby-version"
end

#before "deploy:symlink", "deploy:assets:precompile"
before "deploy:assets:precompile", :config_symlinks, :bundle_install

after "deploy:update_code", :data_symlinks, :config_symlinks

# [Deprecation Warning] This API has changed, please hook `deploy:create_symlink` instead of `deploy:symlink`.  
# ????????????????