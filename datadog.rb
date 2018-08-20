# frozen_string_literal: true

require 'sinatra'
require 'ddtrace'
require 'ddtrace/contrib/sinatra/tracer'
require 'sidekiq'

Datadog.configure do |c|
  c.use :sinatra, service_name: 'enlightend-production'
  c.use :sidekiq, service_name: 'enlightend-production-sidekiq'
  c.use :http, service_name: 'enlightend-production-http'
end
