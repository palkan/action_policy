# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Failures reasons store
    class FailureReasons
      attr_reader :details

      def initialize
        @details = {}
      end

      def add(policy_or_class, rule)
        policy_class = policy_or_class.is_a?(Class) ? policy_or_class : policy_or_class.class
        details[policy_class.identifier] ||= []
        details[policy_class.identifier] << rule
      end

      def empty?
        details.empty?
      end

      def present?
        !empty?
      end
    end

    # Extend ExecutionResult with `reasons` method
    module ResultFailureReasons
      def reasons
        @reasons ||= FailureReasons.new
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
    #     ex.policy #=> ApplicantPolicy
    #     ex.rule #=> :show?
    #     ex.result.reasons.details  #=> { stage: [:show?] }
    #   end
    #
    # NOTE: the reason key (`stage`) is a policy identifier (underscored class name by default).
    # For namespaced policies it has a form of:
    #
    #   class Admin::UserPolicy < ApplicationPolicy
    #     # ..
    #   end
    #
    #   reasons.details #=> { :"admin/user" => [:show?] }
    #
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
        def included(base)
          base.result_class.include(ResultFailureReasons)
        end
      end

      # rubocop: disable Metrics/MethodLength
      def allowed_to?(rule, record = :__undef__, **options)
        policy = nil

        succeed =
          if record == :__undef__
            policy = self
            with_clean_result { apply(rule) }
          else
            policy = policy_for(record: record, **options)

            policy.apply(rule)
          end

        result.reasons.add(policy, rule) unless succeed
        succeed
      end
      # rubocop: enable Metrics/MethodLength
    end
  end
end
