# frozen_string_literal: true

module ActionPolicy # :nodoc:
  require "action_policy/rails/controller"
  require "action_policy/rails/channel"

  class Railtie < ::Rails::Railtie # :nodoc:
    # Provides Rails-specific configuration,
    # accessible through `Rails.application.config.action_policy`
    module Config
      class << self
        # Define whether we need to extend ApplicationController::Base
        # with the default authorization logic
        attr_accessor :auto_inject_into_controller

        # Define whether we want to specify `current_user` as
        # the default authorization context in controller
        attr_accessor :controller_authorize_current_user

        # Define whether we need to include ActionCable::Channel::Base
        # with the default authorization logic
        attr_accessor :auto_inject_into_channel

        # Define whether we want to specify `current_user` as
        # the default authorization context in channels
        attr_accessor :channel_authorize_current_user

        # Define whether to cache namespaced policy resolution
        # result (e.g. in controllers).
        # Enabled only in production by default.
        attr_accessor :namespace_cache_enabled

        def cache_store=(store)
          # Handle both:
          #   store = :memory
          #   store = :mem_cache, ENV['MEMCACHE']
          if store.is_a?(Symbol) || store.is_a?(Array)
            store = ActiveSupport::Cache.lookup_store(store)
          end

          ActionPolicy.cache_store = store
        end
      end

      self.auto_inject_into_controller = true
      self.controller_authorize_current_user = true
      self.auto_inject_into_channel = true
      self.channel_authorize_current_user = true
      self.namespace_cache_enabled = Rails.env.production?
    end

    config.action_policy = Config

    initializer "action_policy.clear_per_thread_cache" do |app|
      if Rails::VERSION::MAJOR >= 5
        app.executor.to_run { ActionPolicy::PerThreadCache.clear_all }
        app.executor.to_complete { ActionPolicy::PerThreadCache.clear_all }
      else
        require "action_policy/cache_middleware"
        app.middleware.use ActionPolicy::CacheMiddleware
      end
    end

    config.to_prepare do |_app|
      ActionPolicy::LookupChain.namespace_cache_enabled =
        Rails.application.config.action_policy.namespace_cache_enabled

      ActiveSupport.on_load(:action_controller) do
        require "action_policy/rails/scope_matchers/action_controller_params"

        next unless Rails.application.config.action_policy.auto_inject_into_controller

        ActionController::Base.include ActionPolicy::Controller

        next unless Rails.application.config.action_policy.controller_authorize_current_user

        ActionController::Base.authorize :user, through: :current_user
      end

      ActiveSupport.on_load(:action_cable) do
        next unless Rails.application.config.action_policy.auto_inject_into_channel

        ActionCable::Channel::Base.include ActionPolicy::Channel

        next unless Rails.application.config.action_policy.channel_authorize_current_user

        ActionCable::Channel::Base.authorize :user, through: :current_user
      end

      ActiveSupport.on_load(:active_record) do
        require "action_policy/rails/scope_matchers/active_record"
      end
    end
  end
end
