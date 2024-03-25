# config valid only for Capistrano 3.1
#lock '3.3.5'

set :rake, "bundle exec rake"

set :application, "Intermix"
#set :repo_url, "git@github.com:VoicesOfHumanity/InterMix.git"
set :repo_url, "http://github.com/VoicesOfHumanity/InterMix.git"
#set :repository, "http://github.com/VoicesOfHumanity/InterMix.git"
#set :user, 'ploy'
#set :password, 'eu4bd8%t'
set :ssh_options, { :user => "ploy", :port => 22, :forward_agent => true }
#set :scm, :git
#set :scm_username, 'ploy'
#set :scm_password, 'eu4bd8%t'
set :runner, 'ploy'
set :keep_releases, 10
set :deploy_via, :checkout
set :git_shallow_clone, 1
#set :branch, "master"
set :use_sudo, false
set :deploy_to, "/home/apps/intermix"
#default_run_options[:pty] = true

set :rbenv_type, :user # :user or :system, depends on your rbenv setup
set :rbenv_ruby, '2.7.7'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all # default value

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

set :linked_files, %w{config/database.yml config/localsettings.rb config/master.key}
set :linked_dirs, %w{bin log tmp vendor/bundle public/system public/images/data public/ckeditor_assets}


task :data_symlinks do
  run "ln -s /home/apps/intermix/shared/data #{release_path}/public/images/data"
end
#task :config_symlinks do
#  #run "ln -s /home/apps/intermix/shared/config/database.yml #{release_path}/config/database.yml"
#  run "ln -sf /home/apps/intermix/shared/config/database.yml #{latest_release}/config/database.yml"
#  run "ln -sf /home/apps/intermix/shared/config/localsettings.rb #{release_path}/config/localsettings.rb"
#  run "/bin/cp /home/apps/intermix/ruby-version #{release_path}/.ruby-version"
#end

#before "deploy:assets:precompile", :config_symlinks

#after "deploy:update_code", :data_symlinks
