# frozen_string_literal: true

require "rails/generators"

module ActionPolicy
  module Generators
    class PolicyGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def run_install_if_needed
        return if ::Rails.root.join("app/policies/application_policy.rb").exist?
        generate "action_policy:install"
      end

      def create_policy
        template "policy.rb", File.join("app/policies", class_path, "#{file_name}_policy.rb")
      end

      hook_for :test_framework
    end
  end
end
