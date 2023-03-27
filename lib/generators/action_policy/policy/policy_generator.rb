# frozen_string_literal: true

require "rails/generators"

module ActionPolicy
  module Generators
    class PolicyGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      class_option :parent, type: :string, desc: "The parent class for the generated policy"

      def run_install_if_needed
        in_root do
          return if File.exist?("app/policies/application_policy.rb")
        end

        generate "action_policy:install"
      end

      def create_policy
        template "policy.rb", File.join("app/policies", class_path, "#{file_name}_policy.rb")
      end

      hook_for :test_framework

      private

      def parent_class_name
        parent || "ApplicationPolicy"
      end

      def parent
        options[:parent]
      end
    end
  end
end
