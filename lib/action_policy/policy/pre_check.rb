# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Adds callback-style checks to policies to
    # extract common checks from rules.
    #
    #    class ApplicationPolicy < ActionPolicy::Base
    #      authorize :user
    #      pre_check :allow_admins
    #
    #      private
    #        # Allow every action for admins
    #        def allow_admins
    #          allow! if user.admin?
    #        end
    #    end
    #
    # You can specify conditional pre-checks (through `except` / `only`) options
    # and skip already defined pre-checks if necessary.
    #
    #    class UserPolicy < ApplicationPolicy
    #      skip_pre_check :allow_admins, only: :destroy?
    #
    #      def destroy?
    #        user.admin? && !record.admin?
    #      end
    #    end
    module PreCheck
      # Single pre-check instance.
      #
      # Implements filtering logic.
      class Check
        attr_reader :name, :policy_class

        def initialize(policy, name, except: nil, only: nil)
          if !except.nil? && !only.nil?
            raise ArgumentError,
              "Only one of `except` and `only` may be specified for pre-check"
          end

          @policy_class = policy
          @name = name
          @blacklist = Array(except) unless except.nil?
          @whitelist = Array(only) unless only.nil?

          rebuild_filter
        end

        def applicable?(rule)
          return true if filter.nil?
          filter.call(rule)
        end

        def call(policy) = policy.send(name)

        def skip!(except: nil, only: nil)
          if !except.nil? && !only.nil?
            raise ArgumentError,
              "Only one of `except` and `only` may be specified when skipping pre-check"
          end

          if except.nil? && only.nil?
            raise ArgumentError,
              "At least one of `except` and `only` must be specified when skipping pre-check"
          end

          if except
            @whitelist = Array(except)
            @whitelist -= blacklist if blacklist
            @blacklist = nil
          else
            # only
            @blacklist += Array(only) if blacklist
            @whitelist -= Array(only) if whitelist
            @blacklist = Array(only) if filter.nil?
          end

          rebuild_filter
        end
        # rubocop: enable
        # rubocop: enable

        def dup
          self.class.new(
            policy_class,
            name,
            except: blacklist&.dup,
            only: whitelist&.dup
          )
        end

        private

        attr_reader :whitelist, :blacklist, :filter

        def rebuild_filter
          @filter =
            if whitelist
              proc { |rule| whitelist.include?(rule) }
            elsif blacklist
              proc { |rule| !blacklist.include?(rule) }
            end
        end
      end

      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      def run_pre_checks(rule)
        self.class.pre_checks.each do |check|
          next unless check.applicable?(rule)
          check.call(self)
        end

        yield if block_given?
      end

      def __apply__(rule)
        run_pre_checks(rule) { super }
      end

      module ClassMethods # :nodoc:
        def pre_check(*names, **options)
          names.each do |name|
            # do not allow pre-check override
            check = pre_checks.find { _1.name == name }
            raise "Pre-check already defined: #{name}" unless check.nil?

            pre_checks << Check.new(self, name, **options)
          end
        end

        def skip_pre_check(*names, **options)
          names.each do |name|
            check = pre_checks.find { _1.name == name }
            raise "Pre-check not found: #{name}" if check.nil?

            # when no options provided we remove this check completely
            next pre_checks.delete(check) if options.empty?

            # otherwise duplicate and apply skip options
            pre_checks[pre_checks.index(check)] = check.dup.tap { _1.skip!(**options) }
          end
        end

        def pre_checks
          return @pre_checks if instance_variable_defined?(:@pre_checks)

          @pre_checks = if superclass.respond_to?(:pre_checks)
            superclass.pre_checks.dup
          else
            []
          end
        end
      end
    end
  end
end
