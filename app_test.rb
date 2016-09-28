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
end