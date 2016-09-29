config = YAML.load_file('config/capistrano.yml')["deployment"] || {}

# config valid only for current version of Capistrano
lock '3.6.1'

set :application, 'enlightend'
set :repo_url, "git@github.com:osulp/enlightend.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, config['deploy_to']

# Default value for :scm is :git
# set :scm, :git

set :ssh_options, { :forward_agent => true }

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, ['config/capistrano.yml', 'config/sinatra.yml', 'config/god.conf', 'config/unicorn.rb', '.ruby-version',
                       'config/Scholars-Archive.yml']

# Default value for linked_dirs is []
set :linked_dirs, ['log', 'tmp']

# Default value for default_env is {}
set :default_env, { path: "~/.rbenv/shims:~/.rbenv/bin:$PATH" }

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all # default value


# Default value for keep_releases is 5
# set :keep_releases, 5

# touch /tmp/restart.txt to restart the app
set :passenger_restart_with_touch, true
