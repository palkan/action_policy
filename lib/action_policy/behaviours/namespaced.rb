# frozen_string_literal: true

module ActionPolicy
  module Behaviours
    # Adds an ability to lookup policies from current _context_ (namespace):
    #
    #   module Admin
    #     class UsersController < ApplictionController
    #       def index
    #         # uses Admin::UserPolicy if any, otherwise fallbacks to UserPolicy
    #         authorize!
    #       end
    #     end
    #   end
    #
    # Modules nesting is also supported:
    #
    #   module Admin
    #     module Client
    #       class UsersController < ApplictionController
    #         def index
    #           # lookup for Admin::Client::UserPolicy -> Admin::UserPolicy -> UserPolicy
    #           authorize!
    #         end
    #       end
    #     end
    #   end
    #
    # NOTE: in order to support namespaced lookup for non-inferrable resources,
    # you should specify `policy_name` at a class level
    # (instead of `policy_class`, which doesn't take into account namespaces):
    #
    #  class Guest < User
    #     def self.policy_name
    #       "UserPolicy"
    #     end
    #  end
    #
    # NOTE: by default, we use class's name as a policy name; so, for namespaced
    # resources the namespace part is also included:
    #
    #  class Admin
    #    class User
    #    end
    #  end
    #
    #  # search for Admin::UserPolicy, but not for UserPolicy
    #  authorize! Admin::User.new
    #
    # You can access the current authorization namespace through `authorization_namespace` method.
    #
    # You can also define your own namespacing logic by overriding `authorization_namespace`:
    #
    #   def authorization_namespace
    #     return ::Admin if current_user.admin?
    #     return ::Staff if current_user.staff?
    #     # fallback to current namespace
    #     super
    #   end
    module Namespaced
      require "action_policy/ext/module_namespace"
      using ActionPolicy::Ext::ModuleNamespace

      class << self
        def prepended(base)
          base.prepend InstanceMethods
        end

        alias_method :included, :prepended
      end

      module InstanceMethods # :nodoc:
        def authorization_namespace
          return @authorization_namespace if instance_variable_defined?(:@authorization_namespace)
          @authorization_namespace = self.class.namespace
        end
      end
    end
  end
end
