# frozen_string_literal: true

require "spec_helper"

class TestService # :nodoc:
  include ActionPolicy::Behaviour

  class CustomPolicy < UserPolicy
    def some_action?
      true
    end

    alias_rule :aliased_action?, to: :some_action?
  end

  attr_reader :user

  authorize :user

  def initialize(name)
    @user = User.new(name)
  end

  def talk(name)
    user = User.new(name)

    authorize! user, to: :update?

    "OK"
  end

  def say(name)
    user = User.new(name)

    authorize! user, to: :say?, with: CustomPolicy

    "OK"
  end

  def speak(text)
    "The Truth is #{text}"
  end

  def create?
    authorize! User, to: :create?
  end

  def talk?(name)
    user = User.new(name)
    allowed_to?(:talk?, user)
  end

  def filter(users)
    authorized_scope users, type: :data, with: CustomPolicy
  end

  def filter_with_options(users, with_admins: false)
    authorized_scope users, type: :data, with: CustomPolicy, scope_options: {with_admins: with_admins}
  end

  def own(users)
    authorized_scope users, type: :data, as: :own, with: UserPolicy
  end
end

describe "ActionPolicy RSpec matchers" do
  subject { TestService.new("guest") }

  describe "#be_an_alias_of" do
    let(:policy) { TestService::CustomPolicy.new(User.new("guest"), user: User.new("admin")) }
    let(:target) { :some_action? }

    context "when using positive matcher" do
      context "when provided rule is an alias to target policy rule" do
        specify do
          expect(:aliased_action?).to be_an_alias_of(policy, target)
        end
      end

      context "when provided rule is not an alias to target policy rule" do
        specify do
          expect do
            expect(:bad_action?).to be_an_alias_of(policy, target)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end
    end

    context "when using negative matcher" do
      context "when provided rule is not an alias to target policy rule" do
        specify do
          expect(:bad_action?).to_not be_an_alias_of(policy, target)
        end
      end

      context "when provided rule is an alias to target policy rule" do
        specify do
          expect do
            expect(:aliased_action?).to_not be_an_alias_of(policy, target)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end
    end

    context "matcher errors" do
      specify "block is not supported" do
        expect do
          expect { subject }.to be_an_alias_of("PolicyStub", "PolicyRuleStub")
        end.to raise_error(/You must pass an argument rather than a block/)
      end
    end
  end

  describe "#be_authorized_to" do
    let(:target) { User.new("admin") }

    context "when authorization is performed" do
      context "when target is specified" do
        specify do
          expect { subject.talk("admin") }
            .to be_authorized_to(:manage?, target).with(UserPolicy)
        end
      end

      context "when policy is not specified" do
        specify do
          expect { subject.talk("admin") }
            .to be_authorized_to(:manage?, target)
        end
      end

      context "with fallback rule" do
        specify do
          expect { subject.say("admin") }
            .to be_authorized_to(:manage?, target).with(TestService::CustomPolicy)
        end
      end

      context "with compose target matcher" do
        specify do
          expect { subject.talk("admin") }
            .to be_authorized_to(:manage?, an_instance_of(User)).with(UserPolicy)
        end
      end

      context "when target is a class" do
        specify do
          expect { subject.create? }
            .to be_authorized_to(:create?, User).with(UserPolicy)
        end
      end
    end

    context "when authorization hasn't been performed" do
      context "when target doesn't match" do
        specify do
          expect do
            expect { subject.talk("adminos") }
              .to be_authorized_to(:update?, target)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end

      context "when implicit policy doesn't match" do
        specify do
          expect do
            expect { subject.say("adminos") }
              .to be_authorized_to(:manage?, target)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end

      context "when explicit policy doesn't match" do
        specify do
          expect do
            expect { subject.say("admin") }
              .to be_authorized_to(:manage?, target).with(UserPolicy)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end

      context "when rule doesn't match" do
        specify do
          expect do
            expect { subject.say("admin") }
              .to be_authorized_to(:say?, target).with(UserPolicy)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end

      context "when no authorization performed" do
        specify do
          expect do
            expect { subject.speak("admin") }
              .to be_authorized_to(:manage?, target).with(UserPolicy)
          end.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            %r{expected.+to be authorized with UserPolicy#manage?}
          )
        end
      end

      context "when allowed_to? performed" do
        specify do
          expect do
            expect { subject.talk?("admin") }
              .to be_authorized_to(:manage?, target).with(UserPolicy)
          end.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /but no authorization calls have been made/
          )
        end
      end
    end

    context "matcher errors" do
      specify "negation is not supported" do
        expect do
          expect { subject.talk("admin") }
            .not_to be_authorized_to(:update?, target)
        end.to raise_error(/doesn't support negation/)
      end

      specify "block is required" do
        expect do
          expect(subject).to be_authorized_to(:update?, target)
        end.to raise_error(/only supports block expectations/)
      end
    end
  end

  describe "#have_authorized_scope" do
    let(:target) { [User.new("admin")] }

    context "when scoping is performed" do
      specify "with default scope" do
        expect { subject.filter(target) }
          .to have_authorized_scope(:data).with(TestService::CustomPolicy)
      end

      specify "with named scope" do
        expect { subject.own(target) }
          .to have_authorized_scope(:data).with(UserPolicy).as(:own)
      end

      specify "with scope options" do
        expect { subject.filter_with_options(target, with_admins: true) }
          .to have_authorized_scope(:data).with(TestService::CustomPolicy)
          .with_scope_options(with_admins: true)
      end

      specify "with composed scope options" do
        expect { subject.filter_with_options(target, with_admins: true) }
          .to have_authorized_scope(:data).with(TestService::CustomPolicy)
          .with_scope_options(matching(with_admins: a_truthy_value))
      end

      specify "with block" do
        expect { subject.own(target) }.to have_authorized_scope(:data)
          .with(UserPolicy).as(:own)
          .with_target { |target|
            expect(target.first.name).to eq "admin"
          }
      end
    end

    context "when no scoping performed" do
      specify "type mismatch" do
        expect do
          expect { subject.filter(target) }
            .to have_authorized_scope(:datum).with(TestService::CustomPolicy)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          Regexp.new("expected a scoping named :default for type :datum without scope options " \
                     "from TestService::CustomPolicy to have been applied")
        )
      end

      specify "policy mismatch" do
        expect do
          expect { subject.filter(target) }
            .to have_authorized_scope(:data).with(UserPolicy)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          Regexp.new("expected a scoping named :default for type :data without scope options " \
                     "from UserPolicy to have been applied")
        )
      end

      specify "name mismatch" do
        expect do
          expect { subject.own(target) }
            .to have_authorized_scope(:data).with(UserPolicy)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          Regexp.new("expected a scoping named :default for type :data without scope options " \
                     "from UserPolicy to have been applied")
        )
      end

      specify "scope options mismatch" do
        expect do
          expect { subject.filter_with_options(target, with_admins: true) }
            .to have_authorized_scope(:data).with(TestService::CustomPolicy)
            .with_scope_options(with_admins: false)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          Regexp.new("expected a scoping named :default for type :data " \
                     "with scope options {:with_admins=>false} " \
                     "from TestService::CustomPolicy to have been applied")
        )
      end

      specify "composed scope options mismatch" do
        expect do
          expect { subject.filter_with_options(target, with_admins: true) }
            .to have_authorized_scope(:data).with(TestService::CustomPolicy)
            .with_scope_options(matching(with_admins: a_falsey_value))
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          Regexp.new("expected a scoping named :default for type :data " \
                     'with scope options matching {:with_admins=>\(a falsey value\)} ' \
                     "from TestService::CustomPolicy to have been applied")
        )
      end

      specify "block expectation failed" do
        expect do
          expect { subject.own(target) }.to have_authorized_scope(:data)
            .with(UserPolicy).as(:own)
            .with_target { |target|
              expect(target.first.name).to eq "Guest"
            }
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          /^\s+expected: "Guest"\n\s+got: "admin"/
        )
      end
    end
  end
end
