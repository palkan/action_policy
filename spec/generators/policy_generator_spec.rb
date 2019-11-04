# frozen_string_literal: true

require "spec_helper"
require "generators/action_policy/policy/policy_generator"

describe ActionPolicy::Generators::PolicyGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:args) { ["user"] }

  before do
    prepare_destination
    run_generator(args)
  end

  describe "policy" do
    subject { file("app/policies/user_policy.rb") }

    it { is_expected.to exist }
    it { is_expected.to contain(/class UserPolicy < ApplicationPolicy/) }
  end
end
