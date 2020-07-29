# frozen_string_literal: true

require "spec_helper"
require "generators/action_policy/policy/policy_generator"

describe ActionPolicy::Generators::PolicyGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:args) { ["user"] }

  before do
    prepare_destination

    gen = generator(args)
    expect(gen).to receive(:generate).with("action_policy:install")

    silence_stream(STDOUT) { gen.invoke_all }
  end

  describe "policy" do
    subject { file("app/policies/user_policy.rb") }

    specify do
      is_expected.to exist
      is_expected.to contain(/class UserPolicy < ApplicationPolicy/)
    end
  end
end
