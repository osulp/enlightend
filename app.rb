require 'yaml'
require 'json'
require 'open3'
require 'sinatra'
require 'uri'
require 'net/http'
require 'octokit'

##
# Configure the sinatra application with the application base configurations in config/sinatra.yml
configure do
  set(:config) { load_config("sinatra") }
end

##
# /events expects a Github deployment JSON object to be POSTed. See: https://developer.github.com/v3/repos/deployments/
#  The endpoint that this Sinatra app is listening on should be the target of a webhook for "Deployment Status" and "Deployment" for
#  the repository to be deployed using this application.
post "/events" do
  data = JSON.parse request.body.read
  app_name = data['repository']['name']
  environment = data['deployment']['environment']

  app_config = load_config(app_name)

  servers = app_config['deployment'][environment]['servers']
  command = app_config['deployment']['command']
  username = app_config['deployment'][environment]['username']
  app_path = app_config['deployment'][environment]['app_path']
  channel = app_config['deployment']['slack_channel'].empty? ? settings.config['slack']['channel'] : app_config['deployment']['slack_channel']

  prune_gists(settings.config, app_name)

  servers.each do |s|
    cmd = "ssh #{username}@#{s} 'cd -- #{app_path} && #{command.gsub('{environment}', environment)}'"
    o, s = Open3.capture2e(cmd)
    gist = post_gist(app_name, o)
    status_message = set_deploy_status(o, s)
    slack_message(settings.config, "#{app_name} : #{status_message} See gist for logs: #{gist['html_url']}", channel)
    msg = "Deployed #{app_name} to #{s}, command=#{cmd}, gist=#{gist['html_url']}, result: output=#{o}, status=#{s}"
    puts msg
  end

  200
end

##
# Send a slack message to hubot endpoint. Depends on a hubot endpoint capable of handling a token
# and message to send to a slack channel.
# ie. http://some.server/hubot/msg/{channel}
#
# @param config [Hash] the settings.config (sinatra.yml)
# @param msg [String] the message to send to slack
# @param channel [String] the channel name (without the hash symbol) to send a message to
def slack_message(config, msg, channel)
  uri = URI.parse(config['slack']['message_url'].gsub("{channel}", channel))
  payload = { token: config['slack']['token'], msg: msg }

  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/x-www-form-urlencoded'
  req.body = "payload=#{payload.to_json}"

  res = Net::HTTP.start(uri.host, uri.port) do |http|
    http.request(req)
  end
end

##
# Determine and set the deployment status for the slack message
#
# @param cap_out [String] the output of the capistrano ssh command
# @param status [Process::Status] the process status returned
# @return [String] a deployment status message string for slack
def set_deploy_status(cap_out, status)
  if status.success? && !cap_out.include?("deploy:rollback")
    ":thumbsup: : Successfully deployed."
  else
    ":x: : Failed to deploy."
  end
end

##
# Remove recent # of gists for the application deploy logs
#
# @param config [Hash] the settings.config (sinatra.yml)
# @param app_name [String] the application name being deployed
# @param count [Int] defaults to drop 3 recent gists and delete the remainder
def prune_gists(config, app_name, count = 3)
  gists = github_client.gists(config['github']['username'])
    .select {|g| g.files.to_hash.has_key?("#{app_name}_deploy".to_sym) }
    .sort { |a,b| a.created_at <=> b.created_at }
  gists.drop(count).each do |g|
    github_client.delete_gist(g.id)
  end
end

##
# Post a new gist to github with the output from the capistrano remote command
#
# @param app_name [String] the application name being deployed
# @param cap_out [String] the output from the deployment command
# @return [Sawyer::Resource] the gist that was created using Octokit
def post_gist(app_name, cap_out)
  cap_out ||= "No output."

  payload = {
    :description => "#{app_name} deployment on #{DateTime.now.to_s}",
    :public => false,
    :files => {
      "#{app_name}_deploy" => { :content => cap_out }
    }
  }

  github_client.create_gist(payload)
end

##
# Get an instance of the Octokit client for using the Github API
def github_client
  Octokit::Client.new(access_token: settings.config['github']['gist_token'], api_endpoint: settings.config['github']['api_endpoint'])
end

##
# Load a config yml file
#
# @param filename [String] the filename of the configuration yml
def load_config(filename)
  YAML.load_file(File.join(File.dirname(__FILE__), "config/#{filename}.yml"))
end