# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require './datadog' if ENV.fetch('RAILS_ENV', 'development') == 'production'
require './app'

set :run, false
set :raise_errors, true

run Sinatra::Application
