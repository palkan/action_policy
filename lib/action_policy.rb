# frozen_string_literal: true

# ActionPolicy is an authorization framework for Ruby/Rails applications.
#
# It provides a way to write access policies and helpers to check these policies
# in your application.
module ActionPolicy
  class Error < StandardError; end

  require "action_policy/version"
  require "action_policy/base"

  class << self
    # Find a policy class for a target
    def lookup(target, **options)
      # TODO: add lookup chain, replace policy_class with policy_name (symbol)
      # (to make it work with namespaces)
    end
  end
end
