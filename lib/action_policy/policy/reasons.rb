# frozen_string_literal: true

unless "".respond_to?(:then)
  require "action_policy/ext/yield_self_then"
  using ActionPolicy::Ext::YieldSelfThen
end

unless {}.respond_to?(:transform_keys)
  require "action_policy/ext/hash_transform_keys"
  using ActionPolicy::Ext::HashTransformKeys
end

module ActionPolicy
  module Policy
    # Failures reasons store
    class FailureReasons
      attr_reader :reasons

      def initialize
        @reasons = {}
      end

      def add(policy_or_class, rule, details = nil)
        policy_class = policy_or_class.is_a?(Module) ? policy_or_class : policy_or_class.class
        reasons[policy_class] ||= []

        if details.nil?
          add_non_detailed_reason reasons[policy_class], rule
        else
          add_detailed_reason reasons[policy_class], with_details(rule, details)
        end
      end

      # Return Hash of the form:
      #   { policy_identifier => [rules, ...] }
      def details
        reasons.transform_keys(&:identifier)
      end

      def empty?
        reasons.empty?
      end

      def present?
        !empty?
      end

      private

      def add_non_detailed_reason(store, rule)
        index =
          if store.last.is_a?(::Hash)
            store.size - 1
          else
            store.size
          end

        store.insert(index, rule)
      end

      def add_detailed_reason(store, detailed_rule)
        store.last.is_a?(::Hash) || store << {}
        store.last.merge!(detailed_rule)
      end

      def with_details(rule, details)
        return rule if details.nil?

        {rule => details}
      end
    end

    # Extend ExecutionResult with `reasons` method
    module ResultFailureReasons
      def reasons
        @reasons ||= FailureReasons.new
      end

      attr_accessor :details

      def clear_details
        @details = nil
      end

      # Add reasons to inspect
      def inspect
        super.then do |str|
          next str if reasons.empty?
          str.sub(/>$/, " (reasons: #{reasons.details})")
        end
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
    #     ex.result.reasons.details  #=> {stage: [:show?]}
    #   end
    #
    # NOTE: the reason key (`stage`) is a policy identifier (underscored class name by default).
    # For namespaced policies it has a form of:
    #
    #   class Admin::UserPolicy < ApplicationPolicy
    #     # ..
    #   end
    #
    #   reasons.details #=> {:"admin/user" => [:show?]}
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
    #
    # NOTE: there is `check?` alias for `allowed_to?`.
    #
    # You can provide additional details to your failure reasons by using
    # a `details: { ... }` option:
    #
    #   class ApplicantPolicy < ApplicationPolicy
    #     def show?
    #       allowed_to?(:show?, object.stage)
    #     end
    #   end
    #
    #   class StagePolicy < ApplicationPolicy
    #     def show?
    #       # Add stage title to the failure reason (if any)
    #       # (could be used by client to show more descriptive message)
    #       details[:title] = record.title
    #
    #       # then perform the checks
    #       user.stages.where(id: record.id).exists?
    #     end
    #   end
    #
    #   # when accessing the reasons
    #   p ex.result.reasons.details #=> { stage: [{show?: {title: "Onboarding"}] }
    #
    # NOTE: when using detailed reasons, the `details` array contains as the last element
    # a hash with ALL details reasons for the policy (in a form of <rule> => <details>).
    #
    module Reasons
      class << self
        def included(base)
          base.result_class.prepend(ResultFailureReasons)
        end
      end

      # Add additional details to the failure reason
      def details
        result.details ||= {}
      end

      def allowed_to?(rule, record = :__undef__, **options)
        res =
          if (record == :__undef__ || record == self.record) && options.empty?
            policy = self
            with_clean_result { apply(rule) }
          else
            policy = policy_for(record: record, **options)

            policy.apply(rule)
            policy.result
          end

        result&.reasons&.add(policy, rule, res.details) if res.fail?

        res.clear_details

        res.success?
      end
    end
  end
end
