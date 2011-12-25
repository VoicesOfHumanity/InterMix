#require 'bundler/capistrano'

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.2'        # Or whatever env you want it to run in.

#set :default_environment, {
#  'PATH' => "/usr/local/rvm/gems/ree/1.8.7/bin:/path/to/.rvm/bin:/path/to/.rvm/ree-1.8.7-2009.10/bin:$PATH",
#  'RUBY_VERSION' => 'ruby 1.8.7',
#  'GEM_HOME'     => '/path/to/.rvm/gems/ree-1.8.7-2010.01',
#  'GEM_PATH'     => '/path/to/.rvm/gems/ree-1.8.7-2010.01',
#  'BUNDLE_PATH'  => '/path/to/.rvm/gems/ree-1.8.7-2010.01'  # If you are using bundler.
#}

set :application, "Intermix"
set :repository, "git@github.com:VoiceOfHumanity/InterMix.git"
#set :local_repository, "ploy@sirius.cr8.com:/home/git/intermix"
set :user, 'ploy'
set :password, 'eu4bd8%t'
set :ssh_options, { :user => "ploy", :port => 22 }
set :scm, :git
set :scm_username, 'ploy'
set :scm_password, 'eu4bd8%t'
set :runner, 'ploy'
set :branch, "master"
set :keep_releases, 10
set :deploy_via, :checkout
set :git_shallow_clone, 1
set :use_sudo, false
set :deploy_to, "/home/apps/intermix"
default_run_options[:pty] = true

towhich = 'live'
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
    run "cd #{release_path} && bundle install"
end
task :data_symlinks do
  run "ln -s /home/apps/intermix/shared/data #{release_path}/public/images/data"
end

after "deploy:update_code", :data_symlinks, :bundle_install