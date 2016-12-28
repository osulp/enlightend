ENV["RACK_ENV"] = 'test'

require './app'
require 'test/unit'
require 'rack/test'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @json = '{ "deployment":{ "environment": "staging" },  "repository": { "name": "web_app" } }'
  end

  def app
    Sinatra::Application
  end

  def test_it_handles_json
    post '/events', @json
    assert last_response.ok?
  end

  def test_it_handles_errors
    begin
      post '/events', '{ "deployment":{ "environment": "staging" },  "repository": { "name": "BOGUS" } }'
    rescue => e
      assert !e.nil?
    end
  end

  def test_it_can_get_a_channel
    app_config = {"deployment" => {"slack_channel" => "default"}}
    deployment_data = {"deployment" => {"payload" => {"notify" => {"room" => "room"}}}}
    assert app.send(:get_channel, app_config, {}) == "default"
    assert app.send(:get_channel, app_config, deployment_data) == "room"
  end
end