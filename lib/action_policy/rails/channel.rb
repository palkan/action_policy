# frozen_string_literal: true

require "active_support/concern"
require "action_policy/behaviour"

module ActionPolicy
  # Channel concern.
  # Add `authorize!` and `allowed_to?` methods.
  module Channel
    extend ActiveSupport::Concern

    include ActionPolicy::Behaviour
    include ActionPolicy::Behaviours::Namespaced
  end
end
