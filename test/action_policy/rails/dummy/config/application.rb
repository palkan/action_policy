# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "rails"
require "action_controller/railtie"
require "action_policy"
require "action_policy/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults [Rails::VERSION::MAJOR, Rails::VERSION::MINOR].map(&:to_s).join(".").to_f
    config.action_controller.allow_forgery_protection = false

    # Hack for Rails 7 alpha
    config.active_record = ActiveSupport::OrderedOptions.new
    config.logger = Logger.new("/dev/null") # rubocop:disable Style/FileNull
    config.eager_load = false
  end
end
