# frozen_string_literal: true

require "spec_helper"

class TestService # :nodoc:
  include ActionPolicy::Behaviour

  class CustomPolicy < UserPolicy; end

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

  def talk?(name)
    user = User.new(name)
    allowed_to?(:talk?, user)
  end

  def filter(users)
    authorized users, type: :data, with: CustomPolicy
  end

  def own(users)
    authorized users, type: :data, as: :own, with: UserPolicy
  end
end

describe "ActionPolicy RSpec matchers" do
  subject { TestService.new("guest") }

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
    end

    context "when no scoping performed" do
      specify "type mismatch" do
        expect do
          expect { subject.filter(target) }
            .to have_authorized_scope(:datum).with(TestService::CustomPolicy)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          %r{expected a scoping named :default for type :datum from TestService::CustomPolicy to have been applied}
        )
      end

      specify "policy mismatch" do
        expect do
          expect { subject.filter(target) }
            .to have_authorized_scope(:data).with(UserPolicy)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          %r{expected a scoping named :default for type :data from UserPolicy to have been applied}
        )
      end

      specify "name mismatch" do
        expect do
          expect { subject.own(target) }
            .to have_authorized_scope(:data).with(UserPolicy)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          %r{expected a scoping named :default for type :data from UserPolicy to have been applied}
        )
      end
    end
  end
end
