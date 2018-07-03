# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "rails"
require "action_controller/railtie"
require "action_policy/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.logger = Logger.new("/dev/null")
    config.eager_load = false
  end
end
