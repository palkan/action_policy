# frozen_string_literal: true

module ActionPolicy
  module Policy
    class FailureReason # :nodoc:
      attr_reader :policy, :rule

      def initialize(policy_or_class, rule)
        @policy = policy_or_class.is_a?(Class) ? policy_or_class : policy_or_class.class
        @rule = rule
      end
    end

    # Failures reasons store
    class FailureReasons
      include Enumerable
      extend Forwardable

      def_delegators :@reasons, :size, :empty?, :last, :each

      def initialize
        @reasons = []
      end

      def add(policy, rule)
        @reasons << FailureReason.new(policy, rule)
      end
    end

    # Provides failure reasons tracking functionality.
    # That allows you to distinguish between the reasons why authorization was rejected.
    #
    # It's helpful when you compose policies (i.e. use one policy within another).
    #
    # For example:
    #
    #   class ApplicantPolicy < ApplicationPolicy
    #     def show?
    #       user.has_permission?(:view_applicants) &&
    #         allowed_to?(:show?, object.stage)
    #     end
    #   end
    #
    # Now when you receive an exception, you have a reasons object, which contains additional
    # information about the failure:
    #
    #   rescue_from ActionPolicy::Unauthorized do |ex|
    #     ex.reasons.messages  #=> { stage: [:show] }
    #   end
    #
    # You can also wrap _local_ rules into `allowed_to?` to populate reasons:
    #
    #   class ApplicantPolicy < ApplicationPolicy
    #     def show?
    #       allowed_to?(:view_applicants?) &&
    #         allowed_to?(:show?, object.stage)
    #     end
    #
    #     def view_applicants?
    #       user.has_permission?(:view_applicants)
    #     end
    #   end
    module Reasons
      class << self
        def prepended(base)
          base.prepend InstanceMethods
        end

        alias included prepended
      end

      attr_reader :reasons

      def with_clean_reasons # :nodoc:
        old_reasons = reasons
        @reasons = nil
        res = yield
        @reasons = old_reasons
        res
      end

      module InstanceMethods # :nodoc:
        def apply(rule)
          @reasons = FailureReasons.new
          super
        end

        # rubocop: disable Metrics/MethodLength
        def allowed_to?(rule, record = :__undef__, **options)
          policy = nil

          succeed =
            if record == :__undef__
              policy = self
              with_clean_reasons { apply(rule) }
            else
              policy = policy_for(record: record, **options)

              policy.apply(rule)
            end

          reasons.add(policy, rule) if reasons && !succeed
          succeed
        end
        # rubocop: enable Metrics/MethodLength
      end
    end
  end
end
