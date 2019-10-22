# frozen_string_literal: true

module ActionPolicy
  module RSpec
    # Adds Pundit-style syntax for testing policies
    module PunditSyntax # :nodoc: all
      module Matchers
        extend ::RSpec::Matchers::DSL

        matcher :permit do |user, record|
          match do |policy|
            permissions.all? do |permission|
              policy.new(record, user: user).apply(permission)
            end
          end
        end
      end

      module DSL
        def permissions(*list, &block)
          describe list.to_sentence do
            let(:permissions) { list }

            instance_eval(&block)
          end
        end
      end

      module PolicyExampleGroup
        include Matchers

        def self.included(base)
          base.metadata[:type] = :policy
          base.extend DSL
          super
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(
    ActionPolicy::RSpec::PunditSyntax::PolicyExampleGroup,
    type: :policy,
    file_path: %r{spec/policies}
  )
end
