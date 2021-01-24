# frozen_string_literal: true

require "ruby-next"

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path(transpile: true)

# ActionPolicy is an authorization framework for Ruby/Rails applications.
#
# It provides a way to write access policies and helpers to check these policies
# in your application.
module ActionPolicy
  class Error < StandardError; end

  # Raised when Action Policy fails to find a policy class for a record.
  class NotFound < Error
    attr_reader :target, :message

    def initialize(target, message = nil)
      @target = target
      @message =
        message ||
        "Couldn't find policy class for #{target.inspect}" \
        "#{target.is_a?(Module) ? "" : " (#{target.class})"}"
    end
  end

  require "action_policy/version"
  require "action_policy/base"
  require "action_policy/lookup_chain"
  require "action_policy/behaviour"
  require "action_policy/i18n" if defined?(::I18n)

  class << self
    attr_accessor :cache_store

    attr_accessor :enforce_predicate_rules_naming

    # Find a policy class for a target
    def lookup(target, allow_nil: false, default: nil, **options)
      LookupChain.call(target, **options) ||
        default ||
        (allow_nil ? nil : raise(NotFound, target))
    end
  end

  require "action_policy/railtie" if defined?(::Rails)
end
