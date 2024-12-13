# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "rails"
require "action_controller/railtie"
require "action_policy"
require "action_policy/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    # Hack for Rails 7 alpha
    config.active_record = ActiveSupport::OrderedOptions.new
    config.logger = Logger.new("/dev/null") # rubocop:disable Style/FileNull
    config.eager_load = false
  end
end
